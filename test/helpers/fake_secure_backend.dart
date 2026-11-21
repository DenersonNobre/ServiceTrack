// Backend falso em memória para os testes do cofre (UC-01.01, TASK-02).
//
// SRP: implementa ISecureKeyValue sem platform channel, com falha
// programável para o caminho ERR_COFRE_INDISPONIVEL.
// Não vai para produção: vive em test/helpers.
//
// Dependências: ports desta fatia.

import 'package:service_track/modules/auth/domain/ports/.index.dart';

/// Dublê de testes do armazenamento seguro.
final class FakeSecureBackend implements ISecureKeyValue {
  /// Cria o dublê; [throwsOnRead]/[throwsOnWrite] simulam I/O falho.
  FakeSecureBackend({this.throwsOnRead = false, this.throwsOnWrite = false});

  /// Quando `true`, [read] lança [StateError].
  final bool throwsOnRead;

  /// Quando `true`, [write] lança [StateError].
  final bool throwsOnWrite;

  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async {
    if (throwsOnRead) {
      throw Exception('backend indisponível (leitura)');
    }
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (throwsOnWrite) {
      throw Exception('backend indisponível (escrita)');
    }
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _values.clear();
  }
}
