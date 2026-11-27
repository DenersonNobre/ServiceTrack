import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';
import 'package:service_track/modules/backup/data/sqlite_backup_service.dart';
import 'package:service_track/modules/backup/domain/ports/backup_failure_codes.dart';
import 'package:service_track/modules/checklists/data/checklist_migration.dart';
import 'package:service_track/modules/customers/data/customer_migration.dart';
import 'package:service_track/modules/customers/data/service_location_migration.dart';
import 'package:service_track/modules/settings/data/settings_migration.dart';
import 'package:service_track/modules/work_orders/data/work_order_migration.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('UC-08.02 - SqliteBackupService Integration', () {
    late SqliteProvider provider;
    late SqliteBackupService service;
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('st_backup_');
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      provider = SqliteProvider(
        dbName: 'test_backup.db',
        dbVersion: 12,
        migrations: [
          CustomerMigration.v1(),
          ServiceLocationMigration.v2(),
          WorkOrderMigration.v3(),
          WorkOrderMigration.v4(),
          WorkOrderMigration.v5(),
          WorkOrderMigration.v6(),
          WorkOrderMigration.v7(),
          ChecklistMigration.v8(),
          WorkOrderMigration.v9(),
          WorkOrderMigration.v10(),
          SettingsMigration.v11(),
          ChecklistMigration.v12(),
        ],
        factory: databaseFactoryFfi,
      );
      service = SqliteBackupService(provider: provider);

      // Inserir dados de teste
      final db = await provider.db;
      await db.insert('customers', {
        'id': 'cust-01',
        'name': 'Empresa Alpha',
        'document': '12.345.678/0001-90',
        'whatsapp': '11999998888',
        'email': 'contato@alpha.com',
        'notes': 'Nota cliente',
        'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      });
      await db.insert('service_locations', {
        'id': 'loc-01',
        'customer_id': 'cust-01',
        'label': 'Matriz',
        'street': 'Rua das Flores',
        'number': '123',
        'neighborhood': 'Centro',
        'city': 'São Paulo',
        'state': 'SP',
        'cep': '01001-000',
        'reference': 'Perto do metrô',
        'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      });
      await db.insert('work_orders', {
        'id': 'wo-01',
        'customer_id': 'cust-01',
        'service_description': 'Reparo de bomba',
        'scheduled_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'status': 'scheduled',
        'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'estimated_value_minor': 15000,
        'estimated_value_currency': 'BRL',
        'estimated_value_scale': 2,
      });
      await db.insert('app_settings', {
        'key': 'require_checklist_template',
        'value': '1',
        'updated_at_utc': DateTime.utc(2026, 1, 1).toIso8601String(),
      });
    });

    tearDown(() async {
      await provider.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('exportBackup gera bytes cifrados com AES e HMAC/GCM', () async {
      final exportResult = await service.exportBackup(password: 'SenhaForte123!');
      expect(exportResult.isSuccess, isTrue);
      final bytes = exportResult.getOrNull()!;
      expect(bytes.length, greaterThan(32));

      // Inspecionar metadados sem restaurar
      final inspectResult = await service.inspectBackup(
        encryptedData: bytes,
        password: 'SenhaForte123!',
      );
      expect(inspectResult.isSuccess, isTrue);
      final meta = inspectResult.getOrNull()!;
      expect(meta.schemaVersion, equals(1));
      expect(meta.recordCounts['customers'], equals(1));
      expect(meta.recordCounts['service_locations'], equals(1));
      expect(meta.recordCounts['work_orders'], equals(1));
      expect(meta.recordCounts['app_settings'], equals(1));
    });

    test('inspectBackup e restoreBackup com senha errada falham fail-closed', () async {
      final exportResult = await service.exportBackup(password: 'SenhaForte123!');
      final bytes = exportResult.getOrNull()!;

      final inspectWrong = await service.inspectBackup(
        encryptedData: bytes,
        password: 'SenhaIncorreta!',
      );
      expect(inspectWrong.isFailure, isTrue);
      expect(inspectWrong.getOrNullFailure()!.code, equals(BackupFailureCodes.invalidPassword));

      final restoreWrong = await service.restoreBackup(
        encryptedData: bytes,
        password: 'SenhaIncorreta!',
      );
      expect(restoreWrong.isFailure, isTrue);
      expect(restoreWrong.getOrNullFailure()!.code, equals(BackupFailureCodes.invalidPassword));
    });

    test('restoreBackup restaura atomicamente substituindo os dados', () async {
      final exportResult = await service.exportBackup(password: 'SenhaForte123!');
      final bytes = exportResult.getOrNull()!;

      // Apagar registros do banco na ordem reversa das foreign keys
      final db = await provider.db;
      await db.delete('work_orders');
      await db.delete('service_locations');
      await db.delete('customers');
      await db.delete('app_settings');

      var countCust = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM customers'));
      expect(countCust, equals(0));

      // Restaurar backup
      final restoreResult = await service.restoreBackup(
        encryptedData: bytes,
        password: 'SenhaForte123!',
      );
      expect(restoreResult.isSuccess, isTrue);

      countCust = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM customers'));
      expect(countCust, equals(1));

      final rows = await db.query('customers', where: 'id = ?', whereArgs: ['cust-01']);
      expect(rows.first['name'], equals('Empresa Alpha'));
    });

    test('dados corrompidos causam falha fail-closed sem afetar o banco', () async {
      final exportResult = await service.exportBackup(password: 'SenhaForte123!');
      final bytes = exportResult.getOrNull()!;
      // Corromper dados
      final corrupted = Uint8List.fromList(bytes);
      corrupted[corrupted.length - 1] ^= 0xFF;

      final result = await service.restoreBackup(
        encryptedData: corrupted,
        password: 'SenhaForte123!',
      );
      expect(result.isFailure, isTrue);
      expect(
        [BackupFailureCodes.corruptedData, BackupFailureCodes.invalidPassword],
        contains(result.getOrNullFailure()!.code),
      );
    });
  });
}
