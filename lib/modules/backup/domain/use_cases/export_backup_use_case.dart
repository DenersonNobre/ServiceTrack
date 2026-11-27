import 'dart:typed_data';

import 'package:kortex_lib/kortex_lib.dart';

import '../ports/backup_failure_codes.dart';
import '../ports/backup_service_port.dart';

/// Caso de uso para exportação segura de backup cifrado (UC-08.02).
final class ExportBackupUseCase {
  const ExportBackupUseCase({required this.service});

  final IBackupServicePort service;

  Future<IResult<Uint8List, ValidationError>> execute({
    required String password,
  }) async {
    final cleanPassword = password.trim();
    if (cleanPassword.length < 6) {
      return const Failure(
        ValidationError(
          code: BackupFailureCodes.weakPassword,
          message: 'A senha de backup deve conter pelo menos 6 caracteres.',
        ),
      );
    }
    return service.exportBackup(password: cleanPassword);
  }
}
