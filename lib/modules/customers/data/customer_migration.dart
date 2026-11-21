// Migração SQLite de clientes (UC-02.01).
//
// SRP: definir schema da tabela customers.

import 'package:dnolib/sqlite/sqlite.dart';

/// Migração v1 da tabela customers.
final class CustomerMigration {
  static const table = 'customers';

  static Migration v1() => Migration(version: 1, scripts: const [
        '''
        CREATE TABLE IF NOT EXISTS customers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          document TEXT,
          whatsapp TEXT NOT NULL,
          email TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
        ''',
        'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)',
        'CREATE INDEX IF NOT EXISTS idx_customers_document ON customers(document)',
      ]);
}
