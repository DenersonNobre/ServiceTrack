// Captura de localização para check-in (INV-SEC-17/19).
//
// SRP: representar resultado tipado de captura/bypass para startService.
// Não acessa GPS, não persiste.

import 'check_in_bypass_reason.dart';
import 'geo_point.dart';

/// Resultado tipado de captura de localização para check-in.
sealed class LocationCapture {
  const LocationCapture();
}

/// Captura GPS válida.
final class LocationCaptured extends LocationCapture {
  const LocationCaptured(this.point);
  final GeoPoint point;
}

/// Bypass explícito e tipado, com motivo auditável.
final class LocationBypassed extends LocationCapture {
  const LocationBypassed({required this.reason});
  final CheckInBypassReason reason;
}
