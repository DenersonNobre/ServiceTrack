import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/auth/domain/ports/.index.dart';
import 'package:service_track/modules/auth/domain/value_objects/.index.dart';
import 'package:service_track/modules/auth/features/biometric_unlock/.index.dart';
import 'package:service_track/modules/auth/ui/lock/.index.dart';

final class _FakeBio implements IBiometricAuthPort {
  _FakeBio(this.result, {this.supported = true});
  BiometricAuthResult result;
  bool supported;
  @override
  Future<bool> canAuthenticate() async => supported;
  @override
  Future<BiometricAuthResult> authenticate() async => result;

  @override
  Future<BiometricAuthResult> authenticateDeviceCredential() async =>
      BiometricAuthResult.unavailable;
}

final class _FakeRepo implements IAuthCredentialRepositoryPort {
  bool biometricsEnabled = true;
  bool pinOk = true;
  int markUnlockedCalls = 0;

  @override
  Future<IResult<String, ValidationError>> saveCredentials({
    required MasterPassword password,
    required SecurityPin pin,
  }) async => const Success('user-1');
  @override
  Future<IResult<bool, ValidationError>> hasCredentials() async =>
      const Success(true);
  @override
  Future<IResult<bool, ValidationError>> verifyPin(String attempt) async =>
      pinOk
          ? const Success(true)
          : const Failure(
              ValidationError(
                code: 'ERR_PIN_INCORRETO_TENTATIVAS_RESTANTES',
                message: 'PIN incorreto.',
              ),
            );
  @override
  Future<IResult<bool, ValidationError>> verifyPassword(String attempt) async =>
      const Success(true);
  @override
  Future<IResult<bool, ValidationError>> isBiometricsEnabled() async =>
      Success(biometricsEnabled);
  @override
  Future<IResult<bool, ValidationError>> setBiometricsEnabled(bool enabled) async {
    biometricsEnabled = enabled;
    return const Success(true);
  }
  @override
  Future<IResult<bool, ValidationError>> isRememberMeEnabled() async =>
      const Success(false);
  @override
  Future<IResult<bool, ValidationError>> setRememberMe(bool enabled) async =>
      const Success(true);
  @override
  Future<IResult<bool, ValidationError>> markUnlocked() async {
    markUnlockedCalls++;
    return const Success(true);
  }
  @override
  Future<IResult<bool, ValidationError>> hasValidRememberedSession() async =>
      const Success(false);
  @override
  Future<IResult<bool, ValidationError>> resetPin({
    required SecurityPin newPin,
  }) async => const Success(true);

  @override
  Future<IResult<bool, ValidationError>> clearAll() async => const Success(true);
}

Widget _build(_FakeBio bio, _FakeRepo repo, {void Function()? onUnlocked}) {
  return MaterialApp(
    home: KortexScope(
      providers: [
        KortexProvider<LockController>(
          create: (_) => LockController(
            biometricUnlock: BiometricUnlockUseCase(biometricAuth: bio),
            repository: repo,
            onUnlocked: onUnlocked,
          ),
          dispose: (c) => c.dispose(),
        ),
      ],
      child: const LockPage(),
    ),
  );
}

void main() {
  testWidgets('SUCESSO biometria -> onUnlocked chamado', (tester) async {
    var unlocked = false;
    await tester.pumpWidget(
      _build(_FakeBio(BiometricAuthResult.success), _FakeRepo(),
          onUnlocked: () => unlocked = true),
    );
    await tester.pumpAndSettle();
    expect(unlocked, isTrue);
  });

  testWidgets('FALHA_LEITURA -> mostra PIN manual', (tester) async {
    var unlocked = false;
    await tester.pumpWidget(
      _build(_FakeBio(BiometricAuthResult.failure), _FakeRepo(),
          onUnlocked: () => unlocked = true),
    );
    await tester.pumpAndSettle();
    expect(unlocked, isFalse);
    expect(find.text('Digite seu PIN'), findsOneWidget);
  });

  testWidgets('CANCELADO -> permanece na tela de PIN e mostra Ativar biometria', (tester) async {
    var unlocked = false;
    final repo = _FakeRepo()..biometricsEnabled = false;
    await tester.pumpWidget(
      _build(_FakeBio(BiometricAuthResult.canceled, supported: true), repo,
          onUnlocked: () => unlocked = true),
    );
    await tester.pumpAndSettle();
    expect(unlocked, isFalse);
    expect(find.text('Digite seu PIN'), findsOneWidget);
    expect(find.byKey(const Key('lock-toggle-biometrics')), findsOneWidget);
    expect(find.byKey(const Key('lock-toggle-remember-me')), findsNothing);
    await tester.tap(find.byKey(const Key('lock-toggle-biometrics')));
    await tester.pumpAndSettle();
    expect(repo.biometricsEnabled, isTrue);
  });

  testWidgets('Sem hardware biometrico -> mostra Lembrar de mim', (tester) async {
    final repo = _FakeRepo()..biometricsEnabled = false;
    await tester.pumpWidget(
      _build(_FakeBio(BiometricAuthResult.unavailable, supported: false), repo),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-toggle-remember-me')), findsOneWidget);
    expect(find.byKey(const Key('lock-toggle-biometrics')), findsNothing);
  });
}
