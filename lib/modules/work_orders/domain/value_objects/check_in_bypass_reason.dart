// Motivos tipados de bypass de GPS no check-in (INV-SEC-17).
//
// SRP: enumerar motivos auditáveis de bypass. Não captura localização.

/// Motivo explícito para bypass de geolocalização no check-in.
enum CheckInBypassReason {
  gpsUnavailable,
  permissionDenied,
  permissionDeniedPermanently,
  timeout;

  /// Código canônico para persistência/auditoria.
  String get code => switch (this) {
        CheckInBypassReason.gpsUnavailable => 'GPS_UNAVAILABLE',
        CheckInBypassReason.permissionDenied => 'PERMISSION_DENIED',
        CheckInBypassReason.permissionDeniedPermanently =>
          'PERMISSION_DENIED_PERMANENTLY',
        CheckInBypassReason.timeout => 'TIMEOUT',
      };

  static CheckInBypassReason? fromCode(String code) => switch (code) {
        'GPS_UNAVAILABLE' => CheckInBypassReason.gpsUnavailable,
        'PERMISSION_DENIED' => CheckInBypassReason.permissionDenied,
        'PERMISSION_DENIED_PERMANENTLY' =>
          CheckInBypassReason.permissionDeniedPermanently,
        'TIMEOUT' => CheckInBypassReason.timeout,
        _ => null,
      };
}
