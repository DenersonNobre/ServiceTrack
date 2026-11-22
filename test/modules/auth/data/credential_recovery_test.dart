import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/auth/data/credential_store/secure_credential_store.dart';
import 'package:service_track/modules/auth/domain/ports/auth_failure_codes.dart';
import 'package:service_track/modules/auth/domain/value_objects/auth_credentials.dart';

import '../../../helpers/fake_secure_backend.dart';

void _slowTest(String description, Future<void> Function() body) {
  test(description, body, timeout: const Timeout(Duration(minutes: 2)));
}

void main() {
  group('UC-01.04 - recuperação de credenciais', () {
    late FakeSecureBackend backend;
    late SecureCredentialStore store;
    late DateTime now;

    setUp(() async {
      backend = FakeSecureBackend();
      now = DateTime.utc(2026, 11, 21, 12, 0, 0);
      store = SecureCredentialStore(
        backend: backend,
        clock: () => now,
        maxAttempts: 3,
        baseLockout: const Duration(seconds: 30),
        maxLockout: const Duration(minutes: 15),
      );
      await store.saveCredentials(
        password: MasterPassword.tryCreate('Segura@2026').getOrNull()!,
        pin: SecurityPin.tryCreate('1234').getOrNull()!,
      );
    });

    _slowTest(
      'resetPin atualiza apenas PIN e preserva senha/identidade (A2/A5)',
      () async {
        final oldUser = (await backend.read(SecureCredentialStore.userIdKey))!;
        final oldPwd = (await backend.read(
          SecureCredentialStore.passwordHashKey,
        ))!;

        final res = await store.resetPin(
          newPin: SecurityPin.tryCreate('654321').getOrNull()!,
        );

        expect(res.isSuccess, isTrue);
        expect((await backend.read(SecureCredentialStore.userIdKey)), oldUser);
        expect(
          (await backend.read(SecureCredentialStore.passwordHashKey)),
          oldPwd,
        );
        expect((await store.verifyPin('654321')).getOrNull(), isTrue);
        expect((await store.verifyPin('1234')).isFailure, isTrue);
      },
    );

    _slowTest('resetPin limpa lockout do PIN (A5)', () async {
      await store.verifyPin('0000');
      await store.verifyPin('0000');
      await store.verifyPin('0000');
      final locked = await store.verifyPin('1234');
      expect(locked.isFailure, isTrue);

      await store.resetPin(newPin: SecurityPin.tryCreate('9999').getOrNull()!);
      final after = await store.verifyPin('9999');
      expect(after.getOrNull(), isTrue);
    });

    _slowTest('verifyPassword aplica rate-limit/backoff (A1)', () async {
      for (var i = 0; i < 3; i++) {
        await store.verifyPassword('errada-$i');
      }
      final blocked = await store.verifyPassword('Segura@2026');
      expect(blocked.isFailure, isTrue);
      final err = blocked.getOrNullFailure()!;
      expect(err.code, AuthFailureCodes.passwordLockedOut);
    });

    _slowTest('lockout de senha expira (A1)', () async {
      for (var i = 0; i < 3; i++) {
        await store.verifyPassword('errada-$i');
      }
      now = now.add(const Duration(seconds: 31));
      final ok = await store.verifyPassword('Segura@2026');
      expect(ok.getOrNull(), isTrue);
    });
  });
}
