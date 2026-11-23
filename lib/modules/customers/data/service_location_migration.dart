// Migração SQLite de locais de atendimento (UC-02.02).
//
// SRP: definir schema da tabela service_locations.

import 'package:kortex_lib/sqlite/sqlite.dart';

/// Migração v2 da tabela service_locations.
final class ServiceLocationMigration {
  static const table = 'service_locations';

  static Migration v2() => Migration(version: 2, scripts: const [
        '''
        CREATE TABLE IF NOT EXISTS service_locations (
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          label TEXT NOT NULL,
          street TEXT NOT NULL,
          number TEXT,
          neighborhood TEXT,
          city TEXT NOT NULL,
          state TEXT,
          cep TEXT,
          reference TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers(id)
        )
        ''',
        'CREATE INDEX IF NOT EXISTS idx_service_locations_customer ON service_locations(customer_id)',
      ]);
}
