// Persistência segura das credenciais do onboarding (UC-01.01, TASK-02).
//
// SRP: cobre KDF-PBKDF2, formato versionado, comparação em tempo constante,
// repositório do cofre (roundtrip, tentativas, bloqueio, backend falho) e
// garantia de nenhum segredo em log.
// Não testa biometria (UC-01.02), tela (TASK-03) nem plugin real em aparelho.

import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/auth/domain/ports/auth_failure_codes.dart';
import 'package:service_track/modules/auth/domain/security/credential_kdf.dart';
import 'package:service_track/modules/auth/domain/value_objects/auth_credentials.dart';
import 'package:service_track/modules/auth/infrastructure/credential_store/secure_credential_store.dart';

import 'helpers/fake_secure_backend.dart';

void main() {
  group('Pbkdf2Sha256', () {
    test('deriva deterministica para mesmas entradas', () {
      final salt = List<int>.generate(16, (i) => i);
      final a = Pbkdf2Sha256.derive(
        password: [1, 2, 3],
        salt: salt,
        iterations: 1200,
      );
      final b = Pbkdf2Sha256.derive(
        password: [1, 2, 3],
        salt: salt,
        iterations: 1200,
      );
      expect(a, b);
    });

    test('muda com senha, salt ou iteracoes distintos', () {
      final salt = List<int>.generate(16, (i) => i);
      final base = Pbkdf2Sha256.derive(
        password: [1, 2, 3],
        salt: salt,
        iterations: 1200,
      );
      final otherPassword = Pbkdf2Sha256.derive(
        password: [9, 9, 9],
        salt: salt,
        iterations: 1200,
      );
      final otherSalt = Pbkdf2Sha256.derive(
        password: [1, 2, 3],
        salt: List<int>.generate(16, (i) => 42 - i),
        iterations: 1200,
      );
      final otherIters = Pbkdf2Sha256.derive(
        password: [1, 2, 3],
        salt: salt,
        iterations: 1201,
      );
      expect(otherPassword, isNot(base));
      expect(otherSalt, isNot(base));
      expect(otherIters, isNot(base));
    });

    test('formato versionado serializa e interpreta', () {
      final hash = CredentialHash.create(
        password: [1, 2, 3],
        iterations: 1200,
      );
      final parsed = CredentialHash.parse(hash.encode());
      expect(parsed.iterations, 1200);
      expect(parsed.salt, hash.salt);
      expect(parsed.digest, hash.digest);
      expect(parsed.matches([1, 2, 3]), isTrue);
      expect(parsed.matches([9, 9, 9]), isFalse);
    });

    test('interpretacao rejeita formato corrompido', () {
      expect(() => CredentialHash.parse('lixo'), throwsFormatException);
      expect(
        () => CredentialHash.parse('v9\$x\$1\$AA\$BB'),
        throwsFormatException,
      );
    });

    test('comparacao em tempo constante', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(constantTimeEquals([1, 2, 3], [1, 2]), isFalse);
    });

    test('calibracao respeita piso e teto', () {
      final iters = Pbkdf2Sha256.calibrateIterations(
        target: const Duration(milliseconds: 1),
        minIterations: 500,
        maxIterations: 4000,
      );
      expect(iters, greaterThanOrEqualTo(500));
      expect(iters, lessThanOrEqualTo(4000));
    });
  });

  group('SecureCredentialStore', () {
    test('salva e verifica PIN e senha', () async {
      final store = SecureCredentialStore(
        backend: FakeSecureBackend(),
        profile: const KdfProfile(iterations: 1200),
      );
      final saved = await store.saveCredentials(
        password: MasterPassword.tryCreate('Segura@2026').getOrThrow(),
        pin: SecurityPin.tryCreate('1234').getOrThrow(),
      );
      expect(saved.isSuccess, isTrue);

      final pinOk = await store.verifyPin('1234');
      expect(pinOk.isSuccess, isTrue);
      final passOk = await store.verifyPassword('Segura@2026');
      expect(passOk.isSuccess, isTrue);
    });

    test('PIN errado falha com tentativas restantes', () async {
      final store = SecureCredentialStore(
        backend: FakeSecureBackend(),
        profile: const KdfProfile(iterations: 1200),
      );
      await store.saveCredentials(
        password: MasterPassword.tryCreate('Segura@2026').getOrThrow(),
        pin: SecurityPin.tryCreate('1234').getOrThrow(),
      );
      final first = await store.verifyPin('9999');
      expect(first.isFailure, isTrue);
      expect(
        first.getOrNullFailure()!.code,
        AuthFailureCodes.pinAttemptsLeft,
      );
      final second = await store.verifyPin('9999');
      expect(
        second.getOrNullFailure()!.code,
        AuthFailureCodes.pinAttemptsLeft,
      );
    });

    test('tres erros bloqueiam mesmo o PIN correto', () async {
      var now = DateTime.utc(2026, 1, 1);
      final store = SecureCredentialStore(
        backend: FakeSecureBackend(),
        profile: const KdfProfile(iterations: 1200),
        clock: () => now,
        baseLockout: const Duration(seconds: 30),
      );
      await store.saveCredentials(
        password: MasterPassword.tryCreate('Segura@2026').getOrThrow(),
        pin: SecurityPin.tryCreate('1234').getOrThrow(),
      );
      await store.verifyPin('9999');
      await store.verifyPin('9998');
      final third = await store.verifyPin('9997');
      expect(
        third.getOrNullFailure()!.code,
        AuthFailureCodes.pinLockedOut,
      );
      final correctWhileLocked = await store.verifyPin('1234');
      expect(
        correctWhileLocked.getOrNullFailure()!.code,
        AuthFailureCodes.pinLockedOut,
      );
      now = now.add(const Duration(seconds: 31));
      final afterLockout = await store.verifyPin('1234');
      expect(afterLockout.isSuccess, isTrue);
    });

    test('senha errada falha com codigo proprio', () async {
      final store = SecureCredentialStore(
        backend: FakeSecureBackend(),
        profile: const KdfProfile(iterations: 1200),
      );
      await store.saveCredentials(
        password: MasterPassword.tryCreate('Segura@2026').getOrThrow(),
        pin: SecurityPin.tryCreate('1234').getOrThrow(),
      );
      final result = await store.verifyPassword('Errada@2026');
      expect(result.isFailure, isTrue);
      expect(
        result.getOrNullFailure()!.code,
        AuthFailureCodes.wrongPassword,
      );
    });

    test('sem credenciais cadastradas falha tipada', () async {
      final store = SecureCredentialStore(
        backend: FakeSecureBackend(),
        profile: const KdfProfile(iterations: 1200),
      );
      final result = await store.verifyPin('1234');
      expect(result.isFailure, isTrue);
      expect(
        result.getOrNullFailure()!.code,
        AuthFailureCodes.noCredentials,
      );
    });

    test('backend indisponivel vira falha tipada', () async {
      final store = SecureCredentialStore(
        backend: FakeSecureBackend(throwsOnRead: true),
        profile: const KdfProfile(iterations: 1200),
      );
      final result = await store.verifyPin('1234');
      expect(result.isFailure, isTrue);
      expect(
        result.getOrNullFailure()!.code,
        AuthFailureCodes.storeUnavailable,
      );
    });

    test('nenhum segredo aparece em toString ou mensagens', () async {
      const pin = '1234';
      const password = 'Segura@2026';
      final store = SecureCredentialStore(
        backend: FakeSecureBackend(),
        profile: const KdfProfile(iterations: 1200),
      );
      await store.saveCredentials(
        password: MasterPassword.tryCreate(password).getOrThrow(),
        pin: SecurityPin.tryCreate(pin).getOrThrow(),
      );
      final wrong = await store.verifyPin('9999');
      final failure = wrong.getOrNullFailure()!;
      final exposed = <String>[
        store.toString(),
        failure.toString(),
        failure.message,
        failure.code,
        CredentialHash.create(password: [1], iterations: 10).toString(),
      ];
      for (final text in exposed) {
        expect(text.contains(pin), isFalse, reason: 'vazou PIN em: $text');
        expect(
          text.contains(password),
          isFalse,
          reason: 'vazou senha em: $text',
        );
      }
      final pinVo = SecurityPin.tryCreate(pin).getOrThrow();
      expect(pinVo.toString().contains(pin), isFalse);
      final passVo = MasterPassword.tryCreate(password).getOrThrow();
      expect(passVo.toString().contains(password), isFalse);
    });
  });
}
