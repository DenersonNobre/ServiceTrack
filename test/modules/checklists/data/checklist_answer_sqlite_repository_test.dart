import 'dart:io';

import 'package:kortex_lib/sqlite/sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/checklists/.index.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('UC-04.06 - ChecklistAnswerSqliteRepository', () {
    late SqliteProvider provider;
    late ChecklistAnswerSqliteRepository repo;
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('st_check_answers_');
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      provider = SqliteProvider(
        dbName: 'test_check_answers.db',
        dbVersion: 8,
        migrations: [ChecklistMigration.v8()],
        factory: databaseFactoryFfi,
      );
      repo = ChecklistAnswerSqliteRepository(provider: provider);
    });

    tearDown(() async {
      await provider.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('salva e lista respostas por OS', () async {
      final a1 = ChecklistAnswer.tryCreate(
        workOrderId: 'wo-1',
        itemId: 'item-1',
        status: ChecklistAnswerStatus.conforme,
        notes: 'ok',
        answeredAtUtc: DateTime.utc(2026, 11, 22, 10),
      ).getOrNull()!;
      final a2 = ChecklistAnswer.tryCreate(
        workOrderId: 'wo-1',
        itemId: 'item-2',
        status: ChecklistAnswerStatus.naoConforme,
        notes: 'vazando',
        answeredAtUtc: DateTime.utc(2026, 11, 22, 10, 5),
      ).getOrNull()!;
      final other = ChecklistAnswer.tryCreate(
        workOrderId: 'wo-2',
        itemId: 'item-1',
        status: ChecklistAnswerStatus.naoAplica,
        answeredAtUtc: DateTime.utc(2026, 11, 22, 11),
      ).getOrNull()!;

      expect((await repo.save(a1)).isSuccess, isTrue);
      expect((await repo.save(a2)).isSuccess, isTrue);
      expect((await repo.save(other)).isSuccess, isTrue);

      final list = await repo.findByWorkOrder('wo-1');
      expect(list.isSuccess, isTrue);
      final items = list.getOrNull()!;
      expect(items.length, 2);
      expect(items.map((e) => e.itemId), containsAll(['item-1', 'item-2']));
      expect(items.firstWhere((e) => e.itemId == 'item-2').status, ChecklistAnswerStatus.naoConforme);
    });

    test('upsert por (workOrderId,itemId)', () async {
      final a1 = ChecklistAnswer.tryCreate(
        workOrderId: 'wo-1',
        itemId: 'item-1',
        status: ChecklistAnswerStatus.naoConforme,
        answeredAtUtc: DateTime.utc(2026, 11, 22, 10),
      ).getOrNull()!;
      final updated = ChecklistAnswer.tryCreate(
        workOrderId: 'wo-1',
        itemId: 'item-1',
        status: ChecklistAnswerStatus.conforme,
        notes: 'corrigido',
        answeredAtUtc: DateTime.utc(2026, 11, 22, 10, 10),
      ).getOrNull()!;

      await repo.save(a1);
      await repo.save(updated);

      final items = (await repo.findByWorkOrder('wo-1')).getOrNull()!;
      expect(items.length, 1);
      expect(items.first.status, ChecklistAnswerStatus.conforme);
      expect(items.first.notes, 'corrigido');
    });
  });
}