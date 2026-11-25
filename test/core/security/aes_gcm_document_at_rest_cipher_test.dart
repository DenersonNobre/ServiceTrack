import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/core/security/aes_gcm_document_at_rest_cipher.dart';

final class _FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }
}

void main() {
  group('AesGcmDocumentAtRestCipher (D-01/C-01)', () {
    test('criptografa e descriptografa round-trip', () async {
      final cipher = AesGcmDocumentAtRestCipher(
        secureStorage: _FakeSecureStorage(),
      );
      const plain = '12345678909';

      final encrypted = await cipher.encrypt(plain);
      expect(encrypted.isSuccess, isTrue);
      final cipherText = encrypted.getOrNull()!;
      expect(cipherText, startsWith('enc:v1:'));
      expect(cipherText, isNot(contains(plain)));

      final decrypted = await cipher.decrypt(cipherText);
      expect(decrypted.isSuccess, isTrue);
      expect(decrypted.getOrNull(), plain);
    });

    test('mesmo plaintext gera ciphertexts diferentes (IV aleatório)', () async {
      final cipher = AesGcmDocumentAtRestCipher(
        secureStorage: _FakeSecureStorage(),
      );
      const plain = '12345678909';
      final a = (await cipher.encrypt(plain)).getOrNull()!;
      final b = (await cipher.encrypt(plain)).getOrNull()!;
      expect(a, isNot(equals(b)));
      expect((await cipher.decrypt(a)).getOrNull(), plain);
      expect((await cipher.decrypt(b)).getOrNull(), plain);
    });

    test('falha fail-closed para payload sem prefixo enc:v1:', () async {
      final cipher = AesGcmDocumentAtRestCipher(
        secureStorage: _FakeSecureStorage(),
      );
      final result = await cipher.decrypt('plaintext-sem-prefixo');
      expect(result.isFailure, isTrue);
    });
  });
}
