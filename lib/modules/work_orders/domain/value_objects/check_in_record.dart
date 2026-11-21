// Registro de check-in da OS (INV-02, INV-SEC-17/18).
//
// SRP: representar evidência de check-in (GPS ou bypass tipado).
// Não captura localização, não persiste.

import 'check_in_bypass_reason.dart';
import 'geo_point.dart';

/// Evidência de check-in para transição de OS.
sealed class CheckInRecord {
  const CheckInRecord();

  /// Momento da evidência em UTC.
  DateTime get timestampUtc;
}

/// Check-in com geolocalização válida.
final class CheckInGps extends CheckInRecord {
  const CheckInGps(this.point);
  final GeoPoint point;

  @override
  DateTime get timestampUtc => point.timestampUtc;

  @override
  String toString() => 'CheckInGps(redacted)';
}

/// Check-in com bypass tipado e auditável (INV-SEC-17).
final class CheckInBypassed extends CheckInRecord {
  const CheckInBypassed({required this.reason, required this.timestampUtc});

  final CheckInBypassReason reason;

  @override
  final DateTime timestampUtc;

  @override
  String toString() => 'CheckInBypassed(reason: ${reason.code})';
}
