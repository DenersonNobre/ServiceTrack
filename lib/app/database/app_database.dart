// Composição do banco SQLite local (EPIC-02+).
//
// SRP: criar e expor SqliteProvider do app com migrations registradas.
// Não contém regra de negócio.

import 'package:dnolib/sqlite/sqlite.dart';

import '../../modules/customers/data/customer_migration.dart';

/// Cria o provider SQLite do app.
SqliteProvider createAppDatabase({String dbName = 'service_track.db'}) {
  return SqliteProvider(
    dbName: dbName,
    dbVersion: 1,
    migrations: [CustomerMigration.v1()],
  );
}
