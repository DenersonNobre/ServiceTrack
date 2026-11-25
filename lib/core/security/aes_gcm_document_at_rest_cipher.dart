// Implementação AES-GCM de cifragem em repouso para PII local (D-01/C-01).
//
// SRP: cifrar/decifrar campos sensíveis com chave mantida no cofre do SO.
// A chave nunca é persistida no SQLite; somente o ciphertext versionado é.
// NÃO conhece entidades de negócio nem tabelas.
//
// Dependências: encrypt (AES-GCM), flutter_secure_storage (Keychain/Keystore).

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kortex_lib/kortex_lib.dart';

import 'document_at_rest_cipher_port.dart';
import 'document_at_rest_failure_codes.dart';

/// Cifra campos sensíveis com AES-GCM 256 e chave armazenada no cofre do SO.
final class AesGcmDocumentAtRestCipher implements IDocumentAtRestCipher {
  AesGcmDocumentAtRestCipher({
    FlutterSecureStorage? secureStorage,
    this._keyStorageKey = _defaultKeyStorageKey,
  }) : _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           );

  static const _defaultKeyStorageKey = 'st.doc.atrest.aes256gcm.v1';
  static const _prefix = 'enc:v1:';
  static const _ivLength = 12;

  final FlutterSecureStorage _secureStorage;
  final String _keyStorageKey;
  enc.Key? _cachedKey;

  Future<IResult<enc.Key, ValidationError>> _getOrCreateKey() async {
    final cached = _cachedKey;
    if (cached != null) return Success(cached);
    try {
      final existing = await _secureStorage.read(key: _keyStorageKey);
      if (existing != null && existing.isNotEmpty) {
        final bytes = base64Decode(existing);
        if (bytes.length == 32) {
          final key = enc.Key(Uint8List.fromList(bytes));
          _cachedKey = key;
          return Success(key);
        }
      }
      final random = Random.secure();
      final bytes = Uint8List.fromList(
        List<int>.generate(32, (_) => random.nextInt(256)),
      );
      await _secureStorage.write(
        key: _keyStorageKey,
        value: base64Encode(bytes),
      );
      final key = enc.Key(bytes);
      _cachedKey = key;
      return Success(key);
    } catch (_) {
      return const Failure(
        ValidationError(
          code: DocumentAtRestFailureCodes.protectionUnavailable,
          message:
              'Não foi possível acessar a proteção em repouso do documento.',
        ),
      );
    }
  }

  @override
  Future<IResult<String, ValidationError>> encrypt(String plainText) async {
    final keyResult = await _getOrCreateKey();
    if (keyResult.isFailure) return Failure(keyResult.getOrNullFailure()!);
    try {
      final key = keyResult.getOrNull()!;
      final iv = enc.IV.fromSecureRandom(_ivLength);
      final encrypter = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.gcm),
      );
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      final payload = base64Encode(iv.bytes + encrypted.bytes);
      return Success('$_prefix$payload');
    } catch (_) {
      return const Failure(
        ValidationError(
          code: DocumentAtRestFailureCodes.protectionUnavailable,
          message:
              'Não foi possível proteger o documento em repouso.',
        ),
      );
    }
  }

  @override
  Future<IResult<String, ValidationError>> decrypt(String cipherText) async {
    if (!cipherText.startsWith(_prefix)) {
      // Legado não-cifrado não deve ser tratado como documento válido para
      // fluxo protegido; fail-closed para evitar leitura ambígua.
      return const Failure(
        ValidationError(
          code: DocumentAtRestFailureCodes.protectionUnavailable,
          message:
              'Documento armazenado sem proteção em repouso reconhecida.',
        ),
      );
    }
    final keyResult = await _getOrCreateKey();
    if (keyResult.isFailure) return Failure(keyResult.getOrNullFailure()!);
    try {
      final key = keyResult.getOrNull()!;
      final payload = base64Decode(cipherText.substring(_prefix.length));
      if (payload.length <= _ivLength) {
        return const Failure(
          ValidationError(
            code: DocumentAtRestFailureCodes.protectionUnavailable,
            message: 'Documento protegido inválido.',
          ),
        );
      }
      final iv = enc.IV(Uint8List.fromList(payload.sublist(0, _ivLength)));
      final encryptedBytes = Uint8List.fromList(payload.sublist(_ivLength));
      final encrypter = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.gcm),
      );
      final plain = encrypter.decrypt(enc.Encrypted(encryptedBytes), iv: iv);
      return Success(plain);
    } catch (_) {
      return const Failure(
        ValidationError(
          code: DocumentAtRestFailureCodes.protectionUnavailable,
          message:
              'Não foi possível ler o documento protegido em repouso.',
        ),
      );
    }
  }
}
