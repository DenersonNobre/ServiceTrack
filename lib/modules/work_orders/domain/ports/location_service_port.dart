// Porta de geolocalização (UC-03.03, INV-SEC-19/21).
//
// SRP: contrato para captura pontual de localização em foreground.
// Não conhece geolocator, UI ou persistência.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../value_objects/geo_point.dart';

/// Contrato de captura pontual de localização.
abstract interface class ILocationServicePort {
  /// Captura localização atual (foreground, sob demanda).
  Future<IResult<GeoPoint, ValidationError>> getCurrentLocation();
}
