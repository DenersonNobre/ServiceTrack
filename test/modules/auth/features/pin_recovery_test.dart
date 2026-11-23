import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/auth/domain/ports/auth_credential_repository_port.dart';
import 'package:service_track/modules/auth/domain/ports/biometric_auth_port.dart';
import 'package:service_track/modules/auth/domain/value_objects/auth_credentials.dart';
import 'package:service_track/modules/auth/domain/value_objects/biometric_auth_result.dart';
import 'package:service_track/modules/auth/features/recovery/pin_recovery_use_case.dart';

final class _FakeBio implements IBiometricAuthPort {
  BiometricAuthResult deviceResult = BiometricAuthResult.success;
  int deviceCalls = 0;
  @override
  Future<bool> canAuthenticate() async => true;
  @override
  Future<BiometricAuthResult> authenticate() async => BiometricAuthResult.success;
  @override
  Future<BiometricAuthResult> authenticateDeviceCredential() async {
    deviceCalls++;
    return deviceResult;
  }
}

final class _FakeRepo implements IAuthCredentialRepositoryPort {
  bool passwordOk = true;
  int resetCalls = 0;
  SecurityPin? lastPin;

  @override
  Future<IResult<bool, ValidationError>> verifyPassword(String attempt) async =>
      passwordOk
          ? const Success(true)
          : const Failure(ValidationError(code: 'ERR_SENHA_INCORRETA', message: 'x'));

  @override
  Future<IResult<bool, ValidationError>> resetPin({required SecurityPin newPin}) async {
    resetCalls++;
    lastPin = newPin;
    return const Success(true);
  }

  // unused in these tests
  @override
  Future<IResult<String, ValidationError>> saveCredentials({required MasterPassword password, required SecurityPin pin}) async => const Success('id');
  @override
  Future<IResult<bool, ValidationError>> hasCredentials() async => const Success(true);
  @override
  Future<IResult<bool, ValidationError>> verifyPin(String attempt) async => const Success(true);
  @override
  Future<IResult<bool, ValidationError>> isBiometricsEnabled() async => const Success(false);
  @override
  Future<IResult<bool, ValidationError>> setBiometricsEnabled(bool enabled) async => const Success(true);
  @override
  Future<IResult<bool, ValidationError>> isRememberMeEnabled() async => const Success(false);
  @override
  Future<IResult<bool, ValidationError>> setRememberMe(bool enabled) async => const Success(true);
  @override
  Future<IResult<bool, ValidationError>> markUnlocked() async => const Success(true);
  @override
  Future<IResult<bool, ValidationError>> hasValidRememberedSession() async => const Success(false);
  @override
  Future<IResult<bool, ValidationError>> clearAll() async => const Success(true);
}

void main() {
  group('UC-01.04 PinRecoveryUseCase', () {
    test('SENHA_MESTRE_VALIDA -> permite recadastrar PIN', () async {
      final repo = _FakeRepo();
      final useCase = PinRecoveryUseCase(repository: repo, biometricAuth: _FakeBio());
      final result = await useCase.recoverWithPassword(
        passwordAttempt: 'Segura@2026',
        newPin: SecurityPin.tryCreate('654321').getOrNull()!,
      );
      expect(result.isSuccess, isTrue);
      expect(repo.resetCalls, 1);
      expect(repo.lastPin?.value, '654321');
    });

    test('senha inválida -> não reseta PIN', () async {
      final repo = _FakeRepo()..passwordOk = false;
      final useCase = PinRecoveryUseCase(repository: repo, biometricAuth: _FakeBio());
      final result = await useCase.recoverWithPassword(
        passwordAttempt: 'errada',
        newPin: SecurityPin.tryCreate('654321').getOrNull()!,
      );
      expect(result.isFailure, isTrue);
      expect(repo.resetCalls, 0);
    });

    test('BIOMETRIA_OU_PADRAO_DO_SISTEMA_OPERACIONAL sucesso -> recadastra PIN', () async {
      final repo = _FakeRepo();
      final bio = _FakeBio()..deviceResult = BiometricAuthResult.success;
      final useCase = PinRecoveryUseCase(repository: repo, biometricAuth: bio);
      final result = await useCase.recoverWithDeviceCredential(
        newPin: SecurityPin.tryCreate('654321').getOrNull()!,
      );
      expect(result.isSuccess, isTrue);
      expect(bio.deviceCalls, 1);
      expect(repo.resetCalls, 1);
    });

    test('credencial SO falha/cancela -> não reseta PIN (fail-closed)', () async {
      final repo = _FakeRepo();
      final bio = _FakeBio()..deviceResult = BiometricAuthResult.canceled;
      final useCase = PinRecoveryUseCase(repository: repo, biometricAuth: bio);
      final result = await useCase.recoverWithDeviceCredential(
        newPin: SecurityPin.tryCreate('654321').getOrNull()!,
      );
      expect(result.isFailure, isTrue);
      expect(repo.resetCalls, 0);
    });
  });
}
