import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/auth/data/credential_store/.index.dart';
import 'package:service_track/modules/auth/domain/value_objects/.index.dart';

import '../../../helpers/fake_secure_backend.dart';

void main() {
  group('SecureCredentialStore - settings/sessão (UC-01.02)', () {
    late FakeSecureBackend backend;
    late SecureCredentialStore store;
    late DateTime now;

    setUp(() {
      backend = FakeSecureBackend();
      now = DateTime.utc(2026, 11, 21, 12, 0, 0);
      store = SecureCredentialStore(
        backend: backend,
        clock: () => now,
        rememberedSessionTtl: const Duration(minutes: 15),
      );
    });

    test('hasCredentials false quando vazio, true após save', () async {
      expect((await store.hasCredentials()).getOrNull(), isFalse);
      await store.saveCredentials(
        password: MasterPassword.tryCreate('Segura@2026').getOrNull()!,
        pin: SecurityPin.tryCreate('1234').getOrNull()!,
      );
      expect((await store.hasCredentials()).getOrNull(), isTrue);
    });

    test('biometrics enabled persiste flag', () async {
      expect((await store.isBiometricsEnabled()).getOrNull(), isFalse);
      await store.setBiometricsEnabled(true);
      expect((await store.isBiometricsEnabled()).getOrNull(), isTrue);
    });

    test('remember me + markUnlocked cria sessão válida dentro do TTL', () async {
      await store.setRememberMe(true);
      await store.markUnlocked();
      expect((await store.hasValidRememberedSession()).getOrNull(), isTrue);
    });

    test('sessão lembrada expira após TTL (INV-SEC-08)', () async {
      await store.setRememberMe(true);
      await store.markUnlocked();
      now = now.add(const Duration(minutes: 16));
      expect((await store.hasValidRememberedSession()).getOrNull(), isFalse);
    });

    test('remember me desabilitado invalida sessão', () async {
      await store.setRememberMe(true);
      await store.markUnlocked();
      await store.setRememberMe(false);
      expect((await store.hasValidRememberedSession()).getOrNull(), isFalse);
    });

    test('clearAll remove flags e sessão', () async {
      await store.setBiometricsEnabled(true);
      await store.setRememberMe(true);
      await store.markUnlocked();
      await store.clearAll();
      expect((await store.isBiometricsEnabled()).getOrNull(), isFalse);
      expect((await store.hasValidRememberedSession()).getOrNull(), isFalse);
    });
  });
}
