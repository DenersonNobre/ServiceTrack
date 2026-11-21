// Value Object de geolocalização (UC-03.03, INV-02, INV-SEC-18/20).
//
// SRP: validar e representar coordenada pontual de check-in/check-out.
// Não captura GPS, não persiste, não loga coordenadas.
//
// Dependências: dnolib Result/ValidationError.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

/// Ponto georreferenciado válido para auditoria de atendimento.
final class GeoPoint {
  const GeoPoint._({
    required this.latitude,
    required this.longitude,
    required this.timestampUtc,
  });

  /// Latitude em graus decimais [-90, 90].
  final double latitude;

  /// Longitude em graus decimais [-180, 180].
  final double longitude;

  /// Momento da captura em UTC.
  final DateTime timestampUtc;

  /// Cria um GeoPoint validado (INV-SEC-20).
  static IResult<GeoPoint, ValidationError> tryCreate({
    required double latitude,
    required double longitude,
    required DateTime timestampUtc,
  }) {
    if (!latitude.isFinite || !longitude.isFinite) {
      return const Failure(
        ValidationError(
          code: 'ERR_GEO_DADOS_INVALIDOS',
          message: 'Coordenadas de localização inválidas.',
        ),
      );
    }
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return const Failure(
        ValidationError(
          code: 'ERR_GEO_DADOS_INVALIDOS',
          message: 'Coordenadas de localização inválidas.',
        ),
      );
    }
    return Success(
      GeoPoint._(
        latitude: latitude,
        longitude: longitude,
        timestampUtc: timestampUtc.toUtc(),
      ),
    );
  }

  @override
  String toString() => 'GeoPoint(redacted)';
}
