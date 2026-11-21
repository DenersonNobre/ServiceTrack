import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/customers/data/customer_migration.dart';
import 'package:service_track/modules/customers/data/customer_sqlite_repository.dart';
import 'package:service_track/modules/customers/domain/value_objects/customer.dart';
import 'package:dnolib/sqlite/sqlite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('CustomerSqliteRepository', () {
    late SqliteProvider provider;
    late CustomerSqliteRepository repo;
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('st_customers_');
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      provider = SqliteProvider(
        dbName: 'test_customers.db',
        dbVersion: 1,
        migrations: [CustomerMigration.v1()],
        factory: databaseFactoryFfi,
      );
      repo = CustomerSqliteRepository(provider: provider);
    });

    tearDown(() async {
      await provider.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('save e findById', () async {
      final customer = Customer.tryCreate(
        id: 'c1',
        name: 'Maria Silva',
        document: '52998224725',
        whatsapp: '11999998888',
        email: 'maria@exemplo.com',
        notes: 'Obs',
      ).getOrNull()!;

      final saved = await repo.save(customer);
      expect(saved.isSuccess, isTrue);

      final found = await repo.findById('c1');
      expect(found.getOrNull()?.name.value, 'Maria Silva');
    });

    test('findAll retorna ordenado por nome', () async {
      await repo.save(Customer.tryCreate(id: '2', name: 'Zeca', document: '', whatsapp: '11999998888', email: '', notes: '').getOrNull()!);
      await repo.save(Customer.tryCreate(id: '1', name: 'Ana', document: '', whatsapp: '11999998888', email: '', notes: '').getOrNull()!);
      final all = await repo.findAll();
      expect(all.getOrNull()!.map((c) => c.name.value).toList(), ['Ana', 'Zeca']);
    });
  });
}
