import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/auth/domain/ports/auth_credential_repository_port.dart';
import 'package:service_track/modules/auth/domain/ports/biometric_auth_port.dart';
import 'package:service_track/modules/auth/domain/value_objects/auth_credentials.dart';
import 'package:service_track/modules/auth/domain/value_objects/biometric_auth_result.dart';
import 'package:service_track/modules/auth/features/biometric_unlock/biometric_unlock_use_case.dart';
import 'package:service_track/modules/auth/ui/lock/lock_controller.dart';
import 'package:service_track/modules/auth/ui/lock/lock_page.dart';

final class _NoBio implements IBiometricAuthPort {
  @override
  Future<bool> canAuthenticate() async => false;
  @override
  Future<BiometricAuthResult> authenticate() async =>
      BiometricAuthResult.unavailable;
}

final class _FakeRepo implements IAuthCredentialRepositoryPort {
  int failures = 0;
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
  Future<IResult<bool, ValidationError>> verifyPin(String attempt) async {
    if (failures >= 3) {
      return const Failure(
        ValidationError(
          code: 'ERR_PIN_BLOQUEADO_TEMPORARIAMENTE',
          message: 'PIN bloqueado temporariamente. Tente mais tarde.',
        ),
      );
    }
    if (attempt == '1234') {
      failures = 0;
      return const Success(true);
    }
    failures++;
    if (failures >= 3) {
      return const Failure(
        ValidationError(
          code: 'ERR_PIN_BLOQUEADO_TEMPORARIAMENTE',
          message: 'PIN bloqueado temporariamente. Tente mais tarde.',
        ),
      );
    }
    return const Failure(
      ValidationError(
        code: 'ERR_PIN_INCORRETO_TENTATIVAS_RESTANTES',
        message: 'PIN incorreto. Verifique os dígitos.',
      ),
    );
  }

  @override
  Future<IResult<bool, ValidationError>> verifyPassword(String attempt) async =>
      const Success(true);
  @override
  Future<IResult<bool, ValidationError>> isBiometricsEnabled() async =>
      const Success(false);
  @override
  Future<IResult<bool, ValidationError>> setBiometricsEnabled(bool enabled) async =>
      const Success(true);
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
  Future<IResult<bool, ValidationError>> clearAll() async => const Success(true);
}

Widget _build(_FakeRepo repo, {void Function()? onUnlocked}) {
  return MaterialApp(
    home: KortexScope(
      providers: [
        KortexProvider<LockController>(
          create: (_) => LockController(
            biometricUnlock: BiometricUnlockUseCase(biometricAuth: _NoBio()),
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

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final ch in pin.split('')) {
    await tester.tap(find.text(ch).last);
    await tester.pump();
  }
  await tester.tap(find.text('OK').last);
  await tester.pumpAndSettle();
}

void main() {
  group('UC-01.03 - Desbloqueio por PIN numérico', () {
    testWidgets('PIN correto -> ACESSO_LIBERADO', (tester) async {
      var unlocked = false;
      final repo = _FakeRepo();
      await tester.pumpWidget(_build(repo, onUnlocked: () => unlocked = true));
      await tester.pumpAndSettle();
      await _enterPin(tester, '1234');
      expect(unlocked, isTrue);
      expect(repo.markUnlockedCalls, 1);
    });

    testWidgets('PIN incorreto -> ERR_PIN_INCORRETO_TENTATIVAS_RESTANTES', (tester) async {
      var unlocked = false;
      final repo = _FakeRepo();
      await tester.pumpWidget(_build(repo, onUnlocked: () => unlocked = true));
      await tester.pumpAndSettle();
      await _enterPin(tester, '9999');
      expect(unlocked, isFalse);
      expect(find.text('PIN incorreto. Verifique os dígitos.'), findsOneWidget);
    });

    testWidgets('3x erro -> BLOQUEIO_TEMPORARIO_OU_PEDIR_SENHA', (tester) async {
      var unlocked = false;
      final repo = _FakeRepo();
      await tester.pumpWidget(_build(repo, onUnlocked: () => unlocked = true));
      await tester.pumpAndSettle();
      await _enterPin(tester, '0000');
      await _enterPin(tester, '0000');
      await _enterPin(tester, '0000');
      expect(unlocked, isFalse);
      expect(
        find.text('PIN bloqueado temporariamente. Tente mais tarde.'),
        findsOneWidget,
      );
    });
  });
}
