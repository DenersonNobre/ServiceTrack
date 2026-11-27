import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/core/storage/temporary_file_cleaner.dart';

void main() {
  group('TemporaryFileCleaner', () {
    late Directory tempTestDir;

    setUp(() async {
      tempTestDir = await Directory.systemTemp.createTemp('cleaner_test_');
    });

    tearDown(() async {
      if (await tempTestDir.exists()) {
        await tempTestDir.delete(recursive: true);
      }
    });

    test('limpa arquivos temporários antigos de laudos e evidências', () async {
      final cleaner = TemporaryFileCleaner(
        directoriesToClean: [tempTestDir],
        maxAge: const Duration(hours: 1),
      );

      // Criar arquivo antigo (> 1h)
      final oldFile = File('${tempTestDir.path}/laudo_OS-123.pdf');
      await oldFile.writeAsString('pdf content');
      final past = DateTime.now().subtract(const Duration(hours: 2));
      await oldFile.setLastModified(past);

      // Criar arquivo recente (< 1h)
      final recentFile = File('${tempTestDir.path}/laudo_OS-456.pdf');
      await recentFile.writeAsString('recent content');

      // Criar arquivo não temporário / ignorado (ex: diretório ou outro tipo que não deve ser tocado caso configurado com prefixo/extensão)
      final otherFile = File('${tempTestDir.path}/keep_me.txt');
      await otherFile.writeAsString('keep');
      await otherFile.setLastModified(past);

      final result = await cleaner.cleanOldFiles(
        fileFilter: (entity) {
          final name = entity.uri.pathSegments.last;
          return name.startsWith('laudo_') && name.endsWith('.pdf');
        },
      );

      expect(result.isSuccess, isTrue);
      final count = result.getOrNull()!;
      expect(count, equals(1)); // apenas o oldFile

      expect(await oldFile.exists(), isFalse);
      expect(await recentFile.exists(), isTrue);
      expect(await otherFile.exists(), isTrue);
    });

    test('limpeza forçada limpa todos os arquivos do filtro ignorando idade', () async {
      final cleaner = TemporaryFileCleaner(
        directoriesToClean: [tempTestDir],
      );

      final file1 = File('${tempTestDir.path}/laudo_1.pdf');
      await file1.writeAsString('1');
      final file2 = File('${tempTestDir.path}/laudo_2.pdf');
      await file2.writeAsString('2');

      final result = await cleaner.cleanAll(
        fileFilter: (entity) => entity.uri.pathSegments.last.endsWith('.pdf'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()!, equals(2));
      expect(await file1.exists(), isFalse);
      expect(await file2.exists(), isFalse);
    });
  });
}
