// Migração SQLite de Ordens de Serviço (UC-03.01, UC-03.03).
//
// SRP: definir schema/migrações da tabela work_orders.

import 'package:kortex_lib/sqlite/sqlite.dart';

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

  /// v5: justificativa de cancelamento (UC-03.04).
  static Migration v5() => Migration(version: 5, scripts: const [
        'ALTER TABLE work_orders ADD COLUMN cancellation_reason TEXT',
      ]);

  /// v6: conclusão/checkout/assinatura (UC-03.05, INV-SEC-23/24).
  static Migration v6() => Migration(version: 6, scripts: const [
        'ALTER TABLE work_orders ADD COLUMN check_out_lat REAL',
        'ALTER TABLE work_orders ADD COLUMN check_out_lng REAL',
        'ALTER TABLE work_orders ADD COLUMN check_out_at TEXT',
        'ALTER TABLE work_orders ADD COLUMN signature_name TEXT',
        'ALTER TABLE work_orders ADD COLUMN signature_image_base64 TEXT',
        'ALTER TABLE work_orders ADD COLUMN checklist_mandatory_total INTEGER',
        'ALTER TABLE work_orders ADD COLUMN checklist_answered_mandatory INTEGER',
      ]);

  /// v7: pausa com justificativa (UC-03.04).
  static Migration v7() => Migration(version: 7, scripts: const [
        'ALTER TABLE work_orders ADD COLUMN pause_reason TEXT',
      ]);

  /// v9: vínculo de template de checklist por OS (UC-04.06/07).
  static Migration v9() => Migration(version: 9, scripts: const [
        'ALTER TABLE work_orders ADD COLUMN checklist_template_id TEXT',
      ]);

  /// v10: metadados canônicos de assinatura (UC-04.08, ADR-001, C-04/C-10).
  /// Aditiva; sem backfill/fabricação; sem UPDATE em COMPLETED.
  static Migration v10() => Migration(version: 10, scripts: const [
        'ALTER TABLE work_orders ADD COLUMN signature_signed_at_utc TEXT',
        'ALTER TABLE work_orders ADD COLUMN signature_document_number TEXT',
      ]);
}
