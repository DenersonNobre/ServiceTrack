import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';
import 'package:service_track/modules/backup/domain/entities/backup_metadata.dart';
import 'package:service_track/modules/backup/domain/ports/backup_service_port.dart';
import 'package:service_track/modules/backup/domain/use_cases/export_backup_use_case.dart';
import 'package:service_track/modules/backup/domain/use_cases/inspect_backup_use_case.dart';
import 'package:service_track/modules/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:service_track/modules/backup/ui/backup_controller.dart';
import 'package:service_track/modules/backup/ui/backup_settings_section.dart';

class _MockBackupService implements IBackupServicePort {
  @override
  Future<IResult<Uint8List, ValidationError>> exportBackup({required String password}) async {
    return Success(Uint8List.fromList([1, 2, 3, 4]));
  }

  @override
  Future<IResult<BackupMetadata, ValidationError>> inspectBackup({
    required Uint8List encryptedData,
    required String password,
  }) async {
    return Success(BackupMetadata(
      schemaVersion: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      recordCounts: const {'customers': 3, 'work_orders': 2},
      checksumSha256: 'hash123',
    ));
  }

  @override
  Future<IResult<bool, ValidationError>> restoreBackup({
    required Uint8List encryptedData,
    required String password,
  }) async {
    return const Success(true);
  }
}

void main() {
  group('UC-08.02 - BackupSettingsSection Widget', () {
    late _MockBackupService service;
    late BackupController controller;
    late File testFile;

    setUp(() {
      service = _MockBackupService();
      testFile = File('dummy_backup.stb');

      controller = BackupController(
        exportBackupUseCase: ExportBackupUseCase(service: service),
        inspectBackupUseCase: InspectBackupUseCase(service: service),
        restoreBackupUseCase: RestoreBackupUseCase(service: service),
      );
      controller.localBackups.value = [testFile];
    });

    testWidgets('renderiza títulos, botão e backups disponíveis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BackupSettingsSection(controller: controller),
            ),
          ),
        ),
      );

      expect(find.text('Segurança & Backup Local (RF-13)'), findsOneWidget);
      expect(find.text('Cópia de Segurança Autocontida'), findsOneWidget);
      expect(find.byKey(const Key('backup-export-button')), findsOneWidget);
      expect(find.text('Backups Locais Disponíveis:'), findsOneWidget);
      expect(find.byKey(const Key('backup-restore-btn-0')), findsOneWidget);
    });

    testWidgets('abre e fecha diálogo de exportação', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BackupSettingsSection(controller: controller),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('backup-export-button')));
      await tester.pump();

      expect(find.text('Senha de Proteção'), findsOneWidget);
      expect(find.byKey(const Key('backup-export-password-field')), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pump();

      expect(find.text('Senha de Proteção'), findsNothing);
    });
  });
}
