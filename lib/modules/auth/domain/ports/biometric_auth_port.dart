// Porta de autenticação biométrica (UC-01.02, INV-SEC-09).
//
// SRP: abstrair a capacidade biométrica do SO para o domínio. Não conhece
// local_auth, UI ou armazenamento.
//
// Pattern: Port (Hexagonal) / ISP.

import '../value_objects/biometric_auth_result.dart';

/// Contrato de autenticação biométrica do dispositivo.
abstract interface class IBiometricAuthPort {
  /// Indica se há biometria disponível e utilizável neste momento.
  Future<bool> canAuthenticate();

  /// Solicita autenticação biométrica e retorna desfecho tipado.
  ///
  /// Implementações devem ser fail-closed: qualquer exceção/estado ambíguo
  /// retorna um [BiometricAuthResult] que não libera acesso.
  Future<BiometricAuthResult> authenticate();

  /// Autentica via credencial do SO (biometria ou PIN/padrão/senha do device).
  ///
  /// Usado apenas para recuperação UC-01.04 (INV-SEC-12). Fail-closed.
  Future<BiometricAuthResult> authenticateDeviceCredential();
}
