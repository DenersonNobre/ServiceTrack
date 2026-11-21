// Adapter de geolocalização via geolocator (UC-03.03, INV-SEC-19/21).
//
// SRP: capturar localização foreground sob demanda. Não conhece UI.
// Não rastreia em background. Não loga coordenadas.

import 'dart:async';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/ports/location_service_port.dart';
import '../domain/value_objects/geo_point.dart';

/// Adapter foreground de localização usando geolocator.
final class GeolocatorLocationService implements ILocationServicePort {
  GeolocatorLocationService({
    Future<bool> Function()? isLocationServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<Position> Function(LocationSettings settings)? getCurrentPosition,
  })  : _isLocationServiceEnabled =
            isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _getCurrentPosition = getCurrentPosition ??
            ((settings) => Geolocator.getCurrentPosition(locationSettings: settings));

  final Future<bool> Function() _isLocationServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<Position> Function(LocationSettings settings) _getCurrentPosition;

  @override
  Future<IResult<GeoPoint, ValidationError>> getCurrentLocation() async {
    try {
      final enabled = await _isLocationServiceEnabled();
      if (!enabled) {
        return const Failure(ValidationError(
          code: 'ERR_LOCALIZACAO_SERVICO_DESLIGADO',
          message: 'Ative o serviço de localização para fazer check-in.',
        ));
      }
      var permission = await _checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const Failure(ValidationError(
          code: 'ERR_LOCALIZACAO_PERMISSAO_NEGADA',
          message: 'Permissão de localização negada.',
        ));
      }
      if (permission == LocationPermission.deniedForever) {
        return const Failure(ValidationError(
          code: 'ERR_LOCALIZACAO_PERMISSAO_NEGADA_PERMANENTE',
          message: 'Permissão de localização negada permanentemente. Abra as configurações do app.',
        ));
      }
      final pos = await _getCurrentPosition(
        const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = GeoPoint.tryCreate(
        latitude: pos.latitude,
        longitude: pos.longitude,
        timestampUtc: pos.timestamp.toUtc(),
      );
      return switch (point) {
        Success<GeoPoint, ValidationError>(:final value) => Success(value),
        Failure<GeoPoint, ValidationError>() => const Failure(ValidationError(
            code: 'ERR_LOCALIZACAO_DADOS_INVALIDOS',
            message: 'Não foi possível obter uma localização válida.',
          )),
      };
    } on TimeoutException {
      return const Failure(ValidationError(
        code: 'ERR_LOCALIZACAO_TIMEOUT',
        message: 'Tempo esgotado ao obter localização.',
      ));
    } catch (_) {
      return const Failure(ValidationError(
        code: 'ERR_LOCALIZACAO_INDISPONIVEL',
        message: 'Não foi possível obter a localização.',
      ));
    }
  }
}
