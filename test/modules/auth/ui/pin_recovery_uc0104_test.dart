import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/auth/domain/ports/auth_credential_repository_port.dart';
import 'package:service_track/modules/auth/domain/ports/biometric_auth_port.dart';
import 'package:service_track/modules/auth/domain/value_objects/auth_credentials.dart';
import 'package:service_track/modules/auth/domain/value_objects/biometric_auth_result.dart';
import 'package:service_track/modules/auth/features/recovery/pin_recovery_use_case.dart';
import 'package:service_track/modules/auth/ui/recovery/pin_recovery_controller.dart';
import 'package:service_track/modules/auth/ui/recovery/pin_recovery_page.dart';

final class _FakeBio implements IBiometricAuthPort {
  BiometricAuthResult deviceResult = BiometricAuthResult.success;
  @override
  Future<bool> canAuthenticate() async => true;
  @override
  Future<BiometricAuthResult> authenticate() async => BiometricAuthResult.success;
  @override
  Future<BiometricAuthResult> authenticateDeviceCredential() async => deviceResult;
}

final class _FakeRepo implements IAuthCredentialRepositoryPort {
  bool passwordOk = true;
  bool resetCalled = false;
  String? resetPinValue;
  String? storedPin = '1234';
  @override
  Future<IResult<String, ValidationError>> saveCredentials({required MasterPassword password, required SecurityPin pin}) async => const Success('id');
  @override
  Future<IResult<bool, ValidationError>> hasCredentials() async => const Success(true);
  @override
  Future<IResult<bool, ValidationError>> verifyPin(String attempt) async => Success(attempt == storedPin);
  @override
  Future<IResult<bool, ValidationError>> verifyPassword(String attempt) async =>
      passwordOk ? const Success(true) : const Failure(ValidationError(code: 'ERR_SENHA_INCORRETA', message: 'Senha incorreta.'));
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
  Future<IResult<bool, ValidationError>> resetPin({required SecurityPin newPin}) async {
    resetCalled = true;
    resetPinValue = newPin.value;
    storedPin = newPin.value;
    return const Success(true);
  }
  @override
  Future<IResult<bool, ValidationError>> clearAll() async => const Success(true);
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final ch in pin.split('')) {
    await tester.tap(find.text(ch).last);
    await tester.pump();
  }
  await tester.tap(find.text('OK').last);
  await tester.pumpAndSettle();
}

Widget _build(_FakeRepo repo, _FakeBio bio, {void Function()? onRecovered}) {
  return MaterialApp(
    home: KortexScope(
      providers: [
        KortexProvider<PinRecoveryController>(
          create: (_) => PinRecoveryController(
            useCase: PinRecoveryUseCase(repository: repo, biometricAuth: bio),
            repository: repo,
            onRecovered: onRecovered,
          ),
          dispose: (c) => c.dispose(),
        ),
      ],
      child: const PinRecoveryPage(),
    ),
  );
}

void main() {
  group('UC-01.04 - Recuperação de PIN', () {
    testWidgets('SENHA_MESTRE_VALIDA permite recadastrar PIN sem apagar histórico', (tester) async {
      var recovered = false;
      final repo = _FakeRepo();
      await tester.pumpWidget(_build(repo, _FakeBio(), onRecovered: () => recovered = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recover-master-password')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('recover-password-field')), 'Segura@2026');
      await tester.tap(find.byKey(const Key('recover-password-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Cadastre um novo PIN'), findsOneWidget);
      await _enterPin(tester, '654321');

      expect(recovered, isTrue);
      expect(repo.resetCalled, isTrue);
      expect(repo.resetPinValue, '654321');
    });

    testWidgets('BIOMETRIA_OU_PADRAO_DO_SISTEMA_OPERACIONAL permite recadastrar PIN', (tester) async {
      var recovered = false;
      final repo = _FakeRepo();
      final bio = _FakeBio()..deviceResult = BiometricAuthResult.success;
      await tester.pumpWidget(_build(repo, bio, onRecovered: () => recovered = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recover-device-credential')));
      await tester.pumpAndSettle();
      expect(find.text('Cadastre um novo PIN'), findsOneWidget);

      await _enterPin(tester, '654321');
      expect(recovered, isTrue);
      expect(repo.resetCalled, isTrue);
    });

    testWidgets('BIOMETRIA_NAO_CONFIRMADA nao avanca para tela de novo PIN', (tester) async {
      final repo = _FakeRepo();
      final bio = _FakeBio()..deviceResult = BiometricAuthResult.canceled;
      await tester.pumpWidget(_build(repo, bio));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recover-device-credential')));
      await tester.pumpAndSettle();
      expect(find.text('Cadastre um novo PIN'), findsNothing);
      expect(find.text('Autenticação do dispositivo não confirmada.'), findsOneWidget);
    });
  });
}
