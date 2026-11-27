import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/backup/data/backup_file_adapter.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  group('UC-08.02 - BackupFileAdapter', () {
    late Directory tempDir;
    late Directory docsDir;
    late BackupFileAdapter adapter;
    late List<XFile> sharedFiles;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('st_file_temp_');
      docsDir = await Directory.systemTemp.createTemp('st_file_docs_');
      sharedFiles = [];

      adapter = BackupFileAdapter(
        tempDirectoryProvider: () async => tempDir,
        documentsDirectoryProvider: () async => docsDir,
        shareInvoker: (files, {subject, text}) async {
          sharedFiles.addAll(files);
        },
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
      if (await docsDir.exists()) await docsDir.delete(recursive: true);
    });

    test('shareBackupFile grava arquivo temporário e aciona invoker', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final result = await adapter.shareBackupFile(
        bytes: bytes,
        fileName: 'backup_test.stb',
      );

      expect(result.isSuccess, isTrue);
      expect(sharedFiles.length, equals(1));
      expect(sharedFiles.first.path.endsWith('backup_test.stb'), isTrue);
      expect(File(sharedFiles.first.path).existsSync(), isTrue);
    });

    test('saveToDocuments, listLocalBackups e readFileBytes operam com integridade', () async {
      final bytes = Uint8List.fromList([10, 20, 30, 40]);
      final saveResult = await adapter.saveToDocuments(
        bytes: bytes,
        fileName: 'backup_doc.stb',
      );
      expect(saveResult.isSuccess, isTrue);

      final listResult = await adapter.listLocalBackups();
      expect(listResult.isSuccess, isTrue);
      final files = listResult.getOrNull()!;
      expect(files.length, equals(1));
      expect(files.first.path.endsWith('backup_doc.stb'), isTrue);

      final readResult = await adapter.readFileBytes(files.first.path);
      expect(readResult.isSuccess, isTrue);
      expect(readResult.getOrNull()!, equals(bytes));
    });
  });
}
