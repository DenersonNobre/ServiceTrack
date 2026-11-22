// Caso de uso de recuperação de PIN (UC-01.04, INV-SEC-11/12/13).
//
// SRP: orquestrar recuperação por senha mestre ou credencial do SO,
// autorizando resetPin apenas após prova válida. Não conhece UI.
//
// Pattern: Use Case fail-closed; sem bypass de autenticação.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../../domain/ports/auth_credential_repository_port.dart';
import '../../domain/ports/auth_failure_codes.dart';
import '../../domain/ports/biometric_auth_port.dart';
import '../../domain/value_objects/auth_credentials.dart';
import '../../domain/value_objects/biometric_auth_result.dart';

/// Resultado de recuperação de PIN.
typedef PinRecoveryResult = IResult<bool, ValidationError>;

/// Orquestra recuperação de PIN com prova de autenticação.
final class PinRecoveryUseCase {
  /// Cria o caso de uso.
  const PinRecoveryUseCase({
    required this.repository,
    required this.biometricAuth,
  });

  /// Repositório de credenciais.
  final IAuthCredentialRepositoryPort repository;

  /// Porta biométrica/credencial de dispositivo.
  final IBiometricAuthPort biometricAuth;

  /// Recupera por senha mestre válida e redefine PIN.
  Future<PinRecoveryResult> recoverWithPassword({
    required String passwordAttempt,
    required SecurityPin newPin,
  }) async {
    final verified = await repository.verifyPassword(passwordAttempt);
    return switch (verified) {
      Success<bool, ValidationError>() => repository.resetPin(newPin: newPin),
      Failure<bool, ValidationError>(:final value) => Failure(value),
    };
  }

  /// Recupera por credencial do SO e redefine PIN (INV-SEC-12).
  Future<PinRecoveryResult> recoverWithDeviceCredential({
    required SecurityPin newPin,
  }) async {
    final auth = await biometricAuth.authenticateDeviceCredential();
    if (auth != BiometricAuthResult.success) {
      return const Failure(
        ValidationError(
          code: AuthFailureCodes.recoveryUnauthorized,
          message: 'Autenticação do dispositivo não confirmada.',
        ),
      );
    }
    return repository.resetPin(newPin: newPin);
  }
}
