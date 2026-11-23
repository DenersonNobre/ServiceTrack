import 'dart:io';

import 'package:kortex_lib/sqlite/sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/settings/.index.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('UC-07.01 - SettingsSqliteRepository', () {
    late SqliteProvider provider;
    late SettingsSqliteRepository repo;
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('st_settings_');
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      provider = SqliteProvider(
        dbName: 'test_settings.db',
        dbVersion: 11,
        migrations: [SettingsMigration.v11()],
        factory: databaseFactoryFfi,
      );
      repo = SettingsSqliteRepository(provider: provider);
    });

    tearDown(() async {
      await provider.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('carrega defaults quando não há configurações persistidas', () async {
      final result = await repo.load();

      expect(result.isSuccess, isTrue);
      final snapshot = result.getOrNull()!;
      expect(snapshot.requireChecklistTemplate, isTrue);
      expect(snapshot.requireReceiverDocument, isFalse);
    });

    test('persiste e recarrega políticas atualizadas', () async {
      final updated = await repo.update(
        SettingKey.requireChecklistTemplate,
        false,
      );
      expect(updated.isSuccess, isTrue);
      expect(updated.getOrNull()!.requireChecklistTemplate, isFalse);

      final receiver = await repo.update(
        SettingKey.requireReceiverDocument,
        true,
      );
      expect(receiver.isSuccess, isTrue);

      final loaded = await repo.load();
      expect(loaded.isSuccess, isTrue);
      expect(loaded.getOrNull()!.requireChecklistTemplate, isFalse);
      expect(loaded.getOrNull()!.requireReceiverDocument, isTrue);
    });

    test('valor corrompido falha fail-closed com código tipado', () async {
      final db = await provider.db;
      await db.insert(SettingsMigration.table, {
        'key': SettingKey.requireChecklistTemplate.storageKey,
        'value': 'talvez',
        'updated_at_utc': DateTime.utc(2026, 11, 22).toIso8601String(),
      });

      final result = await repo.load();

      expect(result.isFailure, isTrue);
      expect(
        result.getOrNullFailure()?.code,
        SettingsFailureCodes.invalidValue,
      );
    });
  });
}
