import 'package:flutter/foundation.dart';

/// Conteúdo completo dos dados das tabelas para backup/restauração (UC-08.02).
@immutable
final class BackupPayload {
  const BackupPayload({required this.tables});

  factory BackupPayload.fromMap(Map<String, dynamic> map) {
    final tablesMap = <String, List<Map<String, dynamic>>>{};
    for (final entry in map.entries) {
      if (entry.value is List) {
        tablesMap[entry.key] = (entry.value as List)
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return BackupPayload(tables: tablesMap);
  }

  /// Mapeamento de nome da tabela para a lista de registros serializados.
  final Map<String, List<Map<String, dynamic>>> tables;

  /// Calcula a contagem de linhas por tabela.
  Map<String, int> calculateRecordCounts() {
    return tables.map((key, value) => MapEntry(key, value.length));
  }

  Map<String, dynamic> toMap() => tables;
}
