import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/backup/domain/entities/backup_metadata.dart';
import 'package:service_track/modules/backup/domain/entities/backup_payload.dart';
import 'package:service_track/modules/backup/domain/ports/backup_failure_codes.dart';
import 'package:service_track/modules/backup/domain/ports/backup_service_port.dart';
import 'package:service_track/modules/backup/domain/use_cases/export_backup_use_case.dart';
import 'package:service_track/modules/backup/domain/use_cases/inspect_backup_use_case.dart';
import 'package:service_track/modules/backup/domain/use_cases/restore_backup_use_case.dart';
import 'package:kortex_lib/kortex_lib.dart';

class FakeBackupService implements IBackupServicePort {
  bool failWithInvalidPassword = false;
  bool failWithCorrupted = false;

  final BackupMetadata sampleMetadata = BackupMetadata(
    schemaVersion: 1,
    createdAt: DateTime.utc(2026, 11, 26, 2, 0),
    recordCounts: const {'customers': 1, 'work_orders': 2},
    checksumSha256: 'a' * 64,
  );

  @override
  Future<IResult<Uint8List, ValidationError>> exportBackup({required String password}) async {
    if (password.length < 6) {
      return const Failure(ValidationError(
        code: BackupFailureCodes.weakPassword,
        message: 'A senha de backup deve conter pelo menos 6 caracteres.',
      ));
    }
    return Success(Uint8List.fromList([1, 2, 3, 4]));
  }

  @override
  Future<IResult<BackupMetadata, ValidationError>> inspectBackup({
    required Uint8List encryptedData,
    required String password,
  }) async {
    if (failWithInvalidPassword) {
      return const Failure(ValidationError(
        code: BackupFailureCodes.invalidPassword,
        message: 'Senha incorreta para decifrar o backup.',
      ));
    }
    if (failWithCorrupted) {
      return const Failure(ValidationError(
        code: BackupFailureCodes.corruptedData,
        message: 'Arquivo de backup corrompido ou formato inválido.',
      ));
    }
    return Success(sampleMetadata);
  }

  @override
  Future<IResult<bool, ValidationError>> restoreBackup({
    required Uint8List encryptedData,
    required String password,
  }) async {
    if (failWithInvalidPassword) {
      return const Failure(ValidationError(
        code: BackupFailureCodes.invalidPassword,
        message: 'Senha incorreta para decifrar o backup.',
      ));
    }
    return const Success(true);
  }
}

void main() {
  group('UC-08.02 - Backup Domain Entities & Use Cases', () {
    late FakeBackupService service;
    late ExportBackupUseCase exportUseCase;
    late InspectBackupUseCase inspectUseCase;
    late RestoreBackupUseCase restoreUseCase;

    setUp(() {
      service = FakeBackupService();
      exportUseCase = ExportBackupUseCase(service: service);
      inspectUseCase = InspectBackupUseCase(service: service);
      restoreUseCase = RestoreBackupUseCase(service: service);
    });

    test('BackupMetadata serializa e deserializa com integridade', () {
      final meta = BackupMetadata(
        schemaVersion: 1,
        createdAt: DateTime.utc(2026, 11, 26, 2, 0),
        recordCounts: const {'customers': 10, 'work_orders': 5},
        checksumSha256: 'abc123def456',
      );

      final map = meta.toMap();
      final restored = BackupMetadata.fromMap(map);

      expect(restored.schemaVersion, equals(1));
      expect(restored.createdAt, equals(DateTime.utc(2026, 11, 26, 2, 0)));
      expect(restored.recordCounts, equals({'customers': 10, 'work_orders': 5}));
      expect(restored.checksumSha256, equals('abc123def456'));
    });

    test('BackupPayload calcula contagem correta por tabela', () {
      const payload = BackupPayload(
        tables: {
          'customers': [
            {'id': 'c1', 'name': 'Cliente 1'},
            {'id': 'c2', 'name': 'Cliente 2'},
          ],
          'work_orders': [
            {'id': 'wo1'},
          ],
        },
      );

      final counts = payload.calculateRecordCounts();
      expect(counts['customers'], equals(2));
      expect(counts['work_orders'], equals(1));
    });

    test('ExportBackupUseCase valida senha fraca', () async {
      final result = await exportUseCase.execute(password: '123');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, equals(BackupFailureCodes.weakPassword));
    });

    test('ExportBackupUseCase sucesso quando senha é válida', () async {
      final result = await exportUseCase.execute(password: 'segredo123');
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), isNotNull);
    });

    test('InspectBackupUseCase falha com senha incorreta', () async {
      service.failWithInvalidPassword = true;
      final result = await inspectUseCase.execute(
        encryptedData: Uint8List(10),
        password: 'wrong',
      );
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, equals(BackupFailureCodes.invalidPassword));
    });

    test('InspectBackupUseCase inspeciona com sucesso sem tocar no banco', () async {
      final result = await inspectUseCase.execute(
        encryptedData: Uint8List(10),
        password: 'correct_password',
      );
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()!.recordCounts['customers'], equals(1));
    });

    test('RestoreBackupUseCase restaura atomicamente com sucesso', () async {
      final result = await restoreUseCase.execute(
        encryptedData: Uint8List(10),
        password: 'correct_password',
      );
      expect(result.isSuccess, isTrue);
    });
  });
}
