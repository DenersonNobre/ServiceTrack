// Migração SQLite de checklists (UC-04.01).
//
// SRP: definir schema das tabelas checklist_templates e checklist_items.

import 'package:dnolib/sqlite/sqlite.dart';

/// Migração v7 das tabelas de modelos de checklist.
abstract final class ChecklistMigration {
  /// Nome da tabela de templates.
  static const templatesTable = 'checklist_templates';

  /// Nome da tabela de itens de template.
  static const itemsTable = 'checklist_items';

  /// Cria migration v7.
  static Migration v7() => Migration(
        version: 7,
        scripts: const [
          '''
          CREATE TABLE IF NOT EXISTS checklist_templates (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
          ''',
          '''
          CREATE TABLE IF NOT EXISTS checklist_items (
            id TEXT PRIMARY KEY,
            template_id TEXT NOT NULL,
            title TEXT NOT NULL,
            is_required INTEGER NOT NULL DEFAULT 1,
            sort_order INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (template_id) REFERENCES checklist_templates(id) ON DELETE CASCADE
          )
          ''',
          'CREATE INDEX IF NOT EXISTS idx_checklist_items_template ON checklist_items(template_id, sort_order)',
        ],
      );
}
