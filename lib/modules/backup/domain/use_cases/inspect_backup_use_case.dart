import 'dart:typed_data';

import 'package:kortex_lib/kortex_lib.dart';

import '../entities/backup_metadata.dart';
import '../ports/backup_failure_codes.dart';
import '../ports/backup_service_port.dart';

/// Caso de uso para validação e inspeção de metadados do backup (UC-08.02).
final class InspectBackupUseCase {
  const InspectBackupUseCase({required this.service});

  final IBackupServicePort service;

  Future<IResult<BackupMetadata, ValidationError>> execute({
    required Uint8List encryptedData,
    required String password,
  }) async {
    final cleanPassword = password.trim();
    if (cleanPassword.isEmpty) {
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.invalidPassword,
          message: 'Informe a senha de proteção do backup.',
        ),
      );
    }
    if (encryptedData.isEmpty) {
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.corruptedData,
          message: 'Arquivo de backup vazio ou inválido.',
        ),
      );
    }
    return service.inspectBackup(
      encryptedData: encryptedData,
      password: cleanPassword,
    );
  }
}
