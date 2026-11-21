// Adapter local_auth para autenticação biométrica (UC-01.02, INV-SEC-09).
//
// SRP: encapsular o plugin local_auth e mapear resultados/exceções para o enum
// de domínio. Não contém regra de navegação nem UI.
//
// Pattern: Adapter (Hexagonal), fail-closed.

import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

import '../../domain/ports/biometric_auth_port.dart';
import '../../domain/value_objects/biometric_auth_result.dart';

/// Adapter que delega ao [LocalAuthentication].
final class LocalAuthBiometricAdapter implements IBiometricAuthPort {
  /// Cria o adapter; [auth] permite injeção em testes.
  LocalAuthBiometricAdapter({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return canCheck || supported;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BiometricAuthResult> authenticate() async {
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Desbloqueie o ServiceTrack para continuar.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: false,
          sensitiveTransaction: false,
        ),
      );
      return didAuthenticate
          ? BiometricAuthResult.success
          : BiometricAuthResult.failure;
    } on LocalAuthException catch (e) {
      return _mapException(e);
    } catch (_) {
      return BiometricAuthResult.error;
    }
  }

  BiometricAuthResult _mapException(LocalAuthException e) {
    return switch (e.code) {
      LocalAuthExceptionCode.userCanceled ||
      LocalAuthExceptionCode.systemCanceled ||
      LocalAuthExceptionCode.timeout ||
      LocalAuthExceptionCode.userRequestedFallback => BiometricAuthResult.canceled,
      LocalAuthExceptionCode.noBiometricHardware ||
      LocalAuthExceptionCode.noCredentialsSet ||
      LocalAuthExceptionCode.noBiometricsEnrolled ||
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
        BiometricAuthResult.unavailable,
      LocalAuthExceptionCode.temporaryLockout => BiometricAuthResult.lockoutTemporary,
      LocalAuthExceptionCode.biometricLockout => BiometricAuthResult.lockoutPermanent,
      LocalAuthExceptionCode.authInProgress ||
      LocalAuthExceptionCode.uiUnavailable ||
      LocalAuthExceptionCode.deviceError ||
      LocalAuthExceptionCode.unknownError => BiometricAuthResult.error,
    };
  }
}
