import 'dart:typed_data';

import 'package:kortex_lib/kortex_lib.dart';

import '../entities/backup_metadata.dart';

/// Contrato da porta do serviço de Backup e Restauração local (UC-08.02, RF-13).
abstract interface class IBackupServicePort {
  /// Exporta o banco de dados completo cifrado com AES-GCM derivado de senha.
  Future<IResult<Uint8List, ValidationError>> exportBackup({
    required String password,
  });

  /// Decifra e inspeciona metadados e integridade do backup sem aplicar no banco de dados.
  Future<IResult<BackupMetadata, ValidationError>> inspectBackup({
    required Uint8List encryptedData,
    required String password,
  });

  /// Restaura atomicamente as tabelas no SQLite dentro de uma transação.
  Future<IResult<bool, ValidationError>> restoreBackup({
    required Uint8List encryptedData,
    required String password,
  });
}
