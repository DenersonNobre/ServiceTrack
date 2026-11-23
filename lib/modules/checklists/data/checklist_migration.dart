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

  /// Semeia os modelos embutidos do épico (UC-04.09).
  ///
  /// `INSERT OR IGNORE` mantém a migration idempotente: reabrir o banco na mesma
  /// versão não re-semeia nem duplica itens. Sem esse seed o dropdown de modelo
  /// da OS nasce vazio e a execução de checklist fica inalcançável pela UI.
  static Migration v12() => Migration(
    version: 12,
    scripts: const [
      '''
          INSERT OR IGNORE INTO checklist_templates (id, title, created_at, updated_at)
          VALUES
            ('tpl-builtin-instalacao', 'Instalação Split', datetime('now'), datetime('now')),
            ('tpl-builtin-manutencao', 'Manutenção Preventiva', datetime('now'), datetime('now')),
            ('tpl-builtin-vistoria', 'Vistoria Rápida', datetime('now'), datetime('now'))
          ''',
      '''
          INSERT OR IGNORE INTO checklist_items (id, template_id, title, is_required, sort_order)
          VALUES
            ('tpl-builtin-instalacao-1', 'tpl-builtin-instalacao', 'Conferir local e infraestrutura elétrica', 1, 0),
            ('tpl-builtin-instalacao-2', 'tpl-builtin-instalacao', 'Fixar unidades interna e externa', 1, 1),
            ('tpl-builtin-instalacao-3', 'tpl-builtin-instalacao', 'Testar refrigeração, drenagem e ruído', 1, 2),
            ('tpl-builtin-manutencao-1', 'tpl-builtin-manutencao', 'Limpar filtros e serpentinas', 1, 0),
            ('tpl-builtin-manutencao-2', 'tpl-builtin-manutencao', 'Medir corrente e tensão do equipamento', 1, 1),
            ('tpl-builtin-manutencao-3', 'tpl-builtin-manutencao', 'Verificar pressão do gás e vazamentos', 1, 2),
            ('tpl-builtin-vistoria-1', 'tpl-builtin-vistoria', 'Registrar estado geral do equipamento', 1, 0),
            ('tpl-builtin-vistoria-2', 'tpl-builtin-vistoria', 'Fotografar pontos críticos e pendências', 1, 1)
          ''',
    ],
  );
}
