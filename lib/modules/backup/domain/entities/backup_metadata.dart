import 'package:flutter/foundation.dart';

/// Metadados descritivos e verificadores de integridade do backup (UC-08.02).
@immutable
final class BackupMetadata {
  const BackupMetadata({
    required this.schemaVersion,
    required this.createdAt,
    required this.recordCounts,
    required this.checksumSha256,
  });

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    final rawCounts = map['record_counts'] as Map<String, dynamic>? ?? {};
    final counts = rawCounts.map(
      (key, value) => MapEntry(key, (value as num).toInt()),
    );

    return BackupMetadata(
      schemaVersion: (map['schema_version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(
        map['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      ),
      recordCounts: counts,
      checksumSha256: map['checksum_sha256'] as String? ?? '',
    );
  }

  /// Versão estrutural do esquema do backup.
  final int schemaVersion;

  /// Data e hora UTC da geração do backup.
  final DateTime createdAt;

  /// Contagem de registros por tabela incluída.
  final Map<String, int> recordCounts;

  /// Hash SHA-256 do payload descompactado/decifrado para validação de integridade.
  final String checksumSha256;

  Map<String, dynamic> toMap() => {
        'schema_version': schemaVersion,
        'created_at': createdAt.toIso8601String(),
        'record_counts': recordCounts,
        'checksum_sha256': checksumSha256,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupMetadata &&
          runtimeType == other.runtimeType &&
          schemaVersion == other.schemaVersion &&
          createdAt == other.createdAt &&
          checksumSha256 == other.checksumSha256 &&
          mapEquals(recordCounts, other.recordCounts);

  @override
  int get hashCode =>
      schemaVersion.hashCode ^
      createdAt.hashCode ^
      checksumSha256.hashCode ^
      recordCounts.hashCode;
}
