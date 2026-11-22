// Migração SQLite de checklists (UC-04.01, UC-04.06).
//
// SRP: definir schema das tabelas de templates, itens e respostas por OS.

import 'package:dnolib/sqlite/sqlite.dart';

/// Migrações das tabelas de checklists.
abstract final class ChecklistMigration {
  /// Nome da tabela de templates.
  static const templatesTable = 'checklist_templates';

  /// Nome da tabela de itens de template.
  static const itemsTable = 'checklist_items';

  /// Nome da tabela de respostas por OS.
  static const answersTable = 'checklist_answers';

  /// Cria migration v8 (templates, itens e respostas por OS).
  static Migration v8() => Migration(
        version: 8,
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
          '''
          CREATE TABLE IF NOT EXISTS checklist_answers (
            work_order_id TEXT NOT NULL,
            item_id TEXT NOT NULL,
            status TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            answered_at_utc TEXT NOT NULL,
            PRIMARY KEY (work_order_id, item_id)
          )
          ''',
          'CREATE INDEX IF NOT EXISTS idx_checklist_answers_work_order ON checklist_answers(work_order_id)',
        ],
      );
}
