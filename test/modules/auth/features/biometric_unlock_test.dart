import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/auth/domain/ports/biometric_auth_port.dart';
import 'package:service_track/modules/auth/domain/value_objects/biometric_auth_result.dart';
import 'package:service_track/modules/auth/features/biometric_unlock/biometric_unlock_use_case.dart';

final class _FakeBiometricAuthPort implements IBiometricAuthPort {
  _FakeBiometricAuthPort(this._result);
  final BiometricAuthResult _result;
  int calls = 0;

  @override
  Future<bool> canAuthenticate() async => true;

  @override
  Future<BiometricAuthResult> authenticate() async {
    calls++;
    return _result;
  }
}

void main() {
  group('UC-01.02 BiometricUnlockUseCase', () {
    test('SUCESSO -> ENTRADA_DIRETA_HOME', () async {
      final port = _FakeBiometricAuthPort(BiometricAuthResult.success);
      final useCase = BiometricUnlockUseCase(biometricAuth: port);

      final decision = await useCase.execute(biometricsEnabled: true);

      expect(decision, UnlockDecision.grantHome);
      expect(port.calls, 1);
    });

    test('FALHA_LEITURA -> SOLICITAR_PIN_MANUAL', () async {
      final port = _FakeBiometricAuthPort(BiometricAuthResult.failure);
      final useCase = BiometricUnlockUseCase(biometricAuth: port);

      final decision = await useCase.execute(biometricsEnabled: true);

      expect(decision, UnlockDecision.requirePin);
    });

    test('CANCELADO_PELO_USUARIO -> PERMANECER_TELA_PIN', () async {
      final port = _FakeBiometricAuthPort(BiometricAuthResult.canceled);
      final useCase = BiometricUnlockUseCase(biometricAuth: port);

      final decision = await useCase.execute(biometricsEnabled: true);

      expect(decision, UnlockDecision.stayOnPin);
    });

    test('biometria desabilitada -> SOLICITAR_PIN_MANUAL', () async {
      final port = _FakeBiometricAuthPort(BiometricAuthResult.success);
      final useCase = BiometricUnlockUseCase(biometricAuth: port);

      final decision = await useCase.execute(biometricsEnabled: false);

      expect(decision, UnlockDecision.requirePin);
      expect(port.calls, 0);
    });

    test('indisponivel/lockout -> SOLICITAR_PIN_MANUAL (fail-closed)', () async {
      final port = _FakeBiometricAuthPort(BiometricAuthResult.unavailable);
      final useCase = BiometricUnlockUseCase(biometricAuth: port);

      final decision = await useCase.execute(biometricsEnabled: true);

      expect(decision, UnlockDecision.requirePin);
    });
  });
}
