import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';
import 'package:service_track/modules/backup/data/backup_file_adapter.dart';
import 'package:service_track/modules/backup/domain/entities/backup_metadata.dart';
import 'package:service_track/modules/backup/domain/ports/backup_failure_codes.dart';
import 'package:service_track/modules/backup/domain/ports/backup_service_port.dart';
import 'package:service_track/modules/backup/domain/use_cases/export_backup_use_case.dart';
import 'package:service_track/modules/backup/domain/use_cases/inspect_backup_use_case.dart';
import 'package:service_track/modules/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:service_track/modules/backup/ui/backup_controller.dart';

class _FakeService implements IBackupServicePort {
  bool failInspect = false;
  bool failRestore = false;

  @override
  Future<IResult<Uint8List, ValidationError>> exportBackup({required String password}) async {
    return Success(Uint8List.fromList([1, 2, 3, 4]));
  }

  @override
  Future<IResult<BackupMetadata, ValidationError>> inspectBackup({
    required Uint8List encryptedData,
    required String password,
  }) async {
    if (failInspect) {
      return const Failure(ValidationError(
        code: BackupFailureCodes.invalidPassword,
        message: 'Senha incorreta.',
      ));
    }
    return Success(BackupMetadata(
      schemaVersion: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      recordCounts: const {'customers': 5},
      checksumSha256: 'hash123',
    ));
  }

  @override
  Future<IResult<bool, ValidationError>> restoreBackup({
    required Uint8List encryptedData,
    required String password,
  }) async {
    if (failRestore) {
      return const Failure(ValidationError(
        code: BackupFailureCodes.databaseError,
        message: 'Erro no banco.',
      ));
    }
    return const Success(true);
  }
}

void main() {
  group('UC-08.02 - BackupController', () {
    late _FakeService service;
    late Directory tempDir;
    late Directory docsDir;
    late BackupFileAdapter adapter;
    late BackupController controller;

    setUp(() async {
      service = _FakeService();
      tempDir = await Directory.systemTemp.createTemp('st_ctrl_temp_');
      docsDir = await Directory.systemTemp.createTemp('st_ctrl_docs_');

      adapter = BackupFileAdapter(
        tempDirectoryProvider: () async => tempDir,
        documentsDirectoryProvider: () async => docsDir,
        shareInvoker: (_, {subject, text}) async {},
      );

      controller = BackupController(
        exportBackupUseCase: ExportBackupUseCase(service: service),
        inspectBackupUseCase: InspectBackupUseCase(service: service),
        restoreBackupUseCase: RestoreBackupUseCase(service: service),
        fileAdapter: adapter,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
      if (await docsDir.exists()) await docsDir.delete(recursive: true);
    });

    test('exportBackup gera arquivo, compartilha e atualiza estado', () async {
      final success = await controller.exportBackup(password: 'SenhaForte123!');
      expect(success, isTrue);
      expect(controller.errorMessage.value, isNull);
      expect(controller.successMessage.value, contains('Backup gerado com sucesso'));
      expect(controller.localBackups.value.length, equals(1));
    });

    test('inspectBackup valida senha e expõe metadados', () async {
      await controller.exportBackup(password: 'SenhaForte123!');
      final filePath = controller.localBackups.value.first.path;

      final ok = await controller.inspectBackup(filePath: filePath, password: 'SenhaForte123!');
      expect(ok, isTrue);
      expect(controller.inspectedMetadata.value, isNotNull);
      expect(controller.inspectedMetadata.value!.recordCounts['customers'], equals(5));

      service.failInspect = true;
      final fail = await controller.inspectBackup(filePath: filePath, password: 'errada');
      expect(fail, isFalse);
      expect(controller.errorMessage.value, equals('Senha incorreta.'));
    });

    test('confirmRestore executa restore e limpa seleção', () async {
      await controller.exportBackup(password: 'SenhaForte123!');
      final filePath = controller.localBackups.value.first.path;
      await controller.inspectBackup(filePath: filePath, password: 'SenhaForte123!');

      final ok = await controller.confirmRestore(password: 'SenhaForte123!');
      expect(ok, isTrue);
      expect(controller.successMessage.value, contains('Dados restaurados com sucesso'));
      expect(controller.inspectedMetadata.value, isNull);
      expect(controller.selectedBackupPath.value, isNull);
    });
  });
}
