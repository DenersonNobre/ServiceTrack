// Migração SQLite de Ordens de Serviço (UC-03.01).
//
// SRP: definir schema da tabela work_orders.

import 'package:dnolib/sqlite/sqlite.dart';

/// Migração v3 da tabela work_orders.
final class WorkOrderMigration {
  static const table = 'work_orders';

  static Migration v3() => Migration(version: 3, scripts: const [
        '''
        CREATE TABLE IF NOT EXISTS work_orders (
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          service_description TEXT NOT NULL,
          scheduled_at TEXT NOT NULL,
          estimated_value_minor INTEGER NOT NULL,
          estimated_value_currency TEXT NOT NULL DEFAULT 'BRL',
          estimated_value_scale INTEGER NOT NULL DEFAULT 2,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
        ''',
        'CREATE INDEX IF NOT EXISTS idx_work_orders_scheduled ON work_orders(scheduled_at)',
        'CREATE INDEX IF NOT EXISTS idx_work_orders_status ON work_orders(status)',
      ]);
}
