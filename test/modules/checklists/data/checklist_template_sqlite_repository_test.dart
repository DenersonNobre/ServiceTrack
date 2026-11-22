import 'dart:io';

import 'package:dnolib/sqlite/sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/checklists/.index.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('UC-04.01 - ChecklistTemplateSqliteRepository', () {
    late SqliteProvider provider;
    late ChecklistTemplateSqliteRepository repo;
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('st_checklists_');
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      provider = SqliteProvider(
        dbName: 'test_checklists.db',
        dbVersion: 8,
        migrations: [ChecklistMigration.v8()],
        factory: databaseFactoryFfi,
      );
      repo = ChecklistTemplateSqliteRepository(provider: provider);
    });

    tearDown(() async {
      await provider.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('salva, atualiza, lista e remove template com itens', () async {
      final item1 = ChecklistItem.tryCreate(
        id: 'i1',
        title: 'Limpar filtro',
        order: 0,
      ).getOrNull()!;
      final item2 = ChecklistItem.tryCreate(
        id: 'i2',
        title: 'Medir corrente',
        order: 1,
      ).getOrNull()!;
      final tpl = ChecklistTemplate.tryCreate(
        id: 'tpl-1',
        title: 'Instalação Split',
        items: [item1, item2],
      ).getOrNull()!;

      final saved = await repo.save(tpl);
      expect(saved.isSuccess, isTrue);

      final found = await repo.findById('tpl-1');
      expect(found.getOrNull()?.items.length, 2);

      final all = await repo.findAll();
      expect(all.getOrNull()?.length, 1);

      final deleted = await repo.delete('tpl-1');
      expect(deleted.isSuccess, isTrue);
      expect((await repo.findAll()).getOrNull(), isEmpty);
    });
  });
}
