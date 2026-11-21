// Adaptador do cofre sobre flutter_secure_storage (UC-01.01, TASK-02).
//
// SRP: traduz ISecureKeyValue para o plugin com opções de plataforma
// endurecidas (Keychain sem sync, EncryptedSharedPreferences).
// NÃO conhece credencial, hash ou regra de negócio.
// Pattern: Adapter da porta ISecureKeyValue.
//
// Plataforma (INV-SEC-07): iOS `first_unlock_this_device` (sem sync em
// nuvem); Android `encryptedSharedPreferences: true`. Pastas de runners
// nativos (android/, ios/) ainda não existem no repo — a verificação do
// manifesto (allowBackup) fica como débito descoberto no hand-off.
//
// Dependências: flutter_secure_storage (v9), ports desta fatia.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/ports/.index.dart';

/// Backend seguro baseado no Keychain/Keystore do aparelho.
final class FlutterSecureStorageBackend implements ISecureKeyValue {
  /// Cria o backend com opções de plataforma endurecidas.
  const FlutterSecureStorageBackend({
    this._storage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  });

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
