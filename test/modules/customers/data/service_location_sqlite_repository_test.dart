import 'dart:io';

import 'package:dnolib/sqlite/sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/customers/data/customer_migration.dart';
import 'package:service_track/modules/customers/data/service_location_migration.dart';
import 'package:service_track/modules/customers/data/service_location_sqlite_repository.dart';
import 'package:service_track/modules/customers/domain/value_objects/service_location.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ServiceLocationSqliteRepository', () {
    late SqliteProvider provider;
    late ServiceLocationSqliteRepository repo;
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('st_locations_');
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      provider = SqliteProvider(
        dbName: 'test_locations.db',
        dbVersion: 2,
        migrations: [CustomerMigration.v1(), ServiceLocationMigration.v2()],
        factory: databaseFactoryFfi,
      );
      repo = ServiceLocationSqliteRepository(provider: provider);
      final db = await provider.db;
      await db.insert('customers', {
        'id': 'c1',
        'name': 'Cliente',
        'document': null,
        'whatsapp': '11999998888',
        'email': null,
        'notes': '',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    });

    tearDown(() async {
      await provider.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('save e findByCustomerId', () async {
      final loc = ServiceLocation.tryCreate(
        id: 'l1',
        customerId: 'c1',
        label: 'Casa',
        street: 'Rua A',
        number: '10',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        cep: '01001000',
        reference: 'Ref',
      ).getOrNull()!;

      final saved = await repo.save(loc);
      expect(saved.isSuccess, isTrue);

      final found = await repo.findByCustomerId('c1');
      expect(found.getOrNull()!.length, 1);
      expect(found.getOrNull()!.first.label.value, 'Casa');
    });
  });
}
