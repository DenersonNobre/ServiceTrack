// Migração SQLite de Ordens de Serviço (UC-03.01, UC-03.03).
//
// SRP: definir schema/migrações da tabela work_orders.

import 'package:dnolib/sqlite/sqlite.dart';

/// Migrações da tabela work_orders.
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

  /// v4: check-in georreferenciado/auditável (INV-02, INV-SEC-17/18).
  static Migration v4() => Migration(version: 4, scripts: const [
        'ALTER TABLE work_orders ADD COLUMN check_in_lat REAL',
        'ALTER TABLE work_orders ADD COLUMN check_in_lng REAL',
        'ALTER TABLE work_orders ADD COLUMN check_in_at TEXT',
        'ALTER TABLE work_orders ADD COLUMN check_in_source TEXT',
        'ALTER TABLE work_orders ADD COLUMN check_in_bypass_reason TEXT',
      ]);
}
