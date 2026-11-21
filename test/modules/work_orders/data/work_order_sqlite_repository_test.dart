import 'dart:io';

import 'package:dnolib/core/models/money.dart';
import 'package:dnolib/sqlite/sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/work_orders/data/work_order_migration.dart';
import 'package:service_track/modules/work_orders/data/work_order_sqlite_repository.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('WorkOrderSqliteRepository', () {
    late SqliteProvider provider;
    late WorkOrderSqliteRepository repo;
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('st_wo_');
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      provider = SqliteProvider(
        dbName: 'test_wo.db',
        dbVersion: 3,
        migrations: [WorkOrderMigration.v3()],
        factory: databaseFactoryFfi,
      );
      repo = WorkOrderSqliteRepository(provider: provider);
    });

    tearDown(() async {
      await provider.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('save e findAll', () async {
      final wo = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(15000, currencyCode: 'BRL', scale: 2),
      ).getOrNull()!;
      final saved = await repo.save(wo);
      expect(saved.isSuccess, isTrue, reason: saved.isFailure ? saved.getOrNullFailure().toString() : '');
      final all = await repo.findAll();
      expect(all.getOrNull()!.length, 1);
      expect(all.getOrNull()!.first.serviceDescription, 'Manutenção');
    });
  });
}
