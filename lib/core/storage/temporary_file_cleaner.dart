// Limpeza de arquivos temporários e cache de compartilhamento (UC-08.03, C-11).
//
// SRP: Varrer diretórios de arquivos temporários e remover arquivos expirados
// ou forçar limpeza completa para mitigar vazamento de PII e economia de espaço local.

import 'dart:io';

import 'package:kortex_lib/kortex_lib.dart';

import 'storage_failure_codes.dart';

/// Filtro de arquivos a serem inspecionados para limpeza.
typedef FileFilter = bool Function(FileSystemEntity entity);

/// Serviço utilitário para higienização e limpeza de arquivos temporários.
final class TemporaryFileCleaner {
  const TemporaryFileCleaner({
    required this.directoriesToClean,
    this.maxAge = const Duration(hours: 24),
  });

  /// Lista de diretórios que devem ser limpos (ex: getTemporaryDirectory()).
  final List<Directory> directoriesToClean;

  /// Idade máxima tolerada antes da deleção de arquivos em [cleanOldFiles].
  final Duration maxAge;

  /// Remove arquivos cuja última modificação seja anterior a [maxAge].
  ///
  /// Retorna o número de arquivos deletados em caso de sucesso.
  Future<IResult<int, ValidationError>> cleanOldFiles({
    FileFilter? fileFilter,
  }) async {
    return _clean(
      shouldDelete: (file, stat) {
        final now = DateTime.now();
        final age = now.difference(stat.modified);
        return age >= maxAge;
      },
      fileFilter: fileFilter,
    );
  }

  /// Remove todos os arquivos que atendam ao [fileFilter], ignorando a idade.
  ///
  /// Retorna o número de arquivos deletados em caso de sucesso.
  Future<IResult<int, ValidationError>> cleanAll({
    FileFilter? fileFilter,
  }) async {
    return _clean(
      shouldDelete: (file, stat) => true,
      fileFilter: fileFilter,
    );
  }

  Future<IResult<int, ValidationError>> _clean({
    required bool Function(File file, FileStat stat) shouldDelete,
    FileFilter? fileFilter,
  }) async {
    try {
      var deletedCount = 0;

      for (final dir in directoriesToClean) {
        if (!await dir.exists()) continue;

        final entities = dir.listSync(recursive: false, followLinks: false);
        for (final entity in entities) {
          if (entity is! File) continue;

          if (fileFilter != null && !fileFilter(entity)) {
            continue;
          }

          final stat = await entity.stat();
          if (shouldDelete(entity, stat)) {
            try {
              await entity.delete();
              deletedCount++;
            } catch (_) {
              // Ignora erro em arquivo individual travado por outro processo
            }
          }
        }
      }

      return Success(deletedCount);
    } catch (e) {
      return Failure(
        ValidationError(
          code: StorageFailureCodes.cleanupFailed,
          message: 'Falha durante a limpeza de arquivos temporários: $e',
        ),
      );
    }
  }
}
