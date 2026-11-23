// Repositório SQLite de modelos de checklist (UC-04.01).
//
// SRP: persistir e carregar templates + itens em transação atômica SQLite.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import '../domain/entities/checklist_template.dart';
import '../domain/ports/checklist_failure_codes.dart';
import '../domain/ports/checklist_template_repository_port.dart';
import 'checklist_migration.dart';

/// Adapter SQLite da porta [IChecklistTemplateRepositoryPort].
final class ChecklistTemplateSqliteRepository
    implements IChecklistTemplateRepositoryPort {
  /// Cria o repositório sobre [provider].
  ChecklistTemplateSqliteRepository({required this.provider});

  /// Provider SQLite da `dnolib`.
  final SqliteProvider provider;

  @override
  Future<IResult<ChecklistTemplate, ValidationError>> save(
    ChecklistTemplate template,
  ) async {
    try {
      final db = await provider.db;
      final now = DateTime.now().toUtc().toIso8601String();
      await db.transaction((txn) async {
        final existing = await txn.query(
          ChecklistMigration.templatesTable,
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [template.id],
          limit: 1,
        );
        if (existing.isEmpty) {
          await txn.insert(ChecklistMigration.templatesTable, {
            'id': template.id,
            'title': template.title,
            'created_at': now,
            'updated_at': now,
          });
        } else {
          await txn.update(
            ChecklistMigration.templatesTable,
            {'title': template.title, 'updated_at': now},
            where: 'id = ?',
            whereArgs: [template.id],
          );
          await txn.delete(
            ChecklistMigration.itemsTable,
            where: 'template_id = ?',
            whereArgs: [template.id],
          );
        }
        for (final item in template.items) {
          await txn.insert(ChecklistMigration.itemsTable, {
            'id': item.id,
            'template_id': template.id,
            'title': item.title,
            'is_required': item.isRequired ? 1 : 0,
            'sort_order': item.order,
          });
        }
      });
      return Success(template);
    } on Exception {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.persistence,
          message: 'Não foi possível salvar o modelo de checklist.',
        ),
      );
    }
  }

  @override
  Future<IResult<List<ChecklistTemplate>, ValidationError>> findAll() async {
    try {
      final db = await provider.db;
      final templateRows = await db.query(
        ChecklistMigration.templatesTable,
        orderBy: 'title COLLATE NOCASE ASC',
      );
      final result = <ChecklistTemplate>[];
      for (final row in templateRows) {
        final id = (row['id'] ?? '') as String;
        final itemRows = await db.query(
          ChecklistMigration.itemsTable,
          where: 'template_id = ?',
          whereArgs: [id],
          orderBy: 'sort_order ASC',
        );
        final mapped = _mapTemplate(row, itemRows);
        if (mapped.isFailure) return Failure(mapped.getOrNullFailure()!);
        result.add(mapped.getOrNull()!);
      }
      return Success(result);
    } on Exception {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.persistence,
          message: 'Não foi possível carregar os modelos de checklist.',
        ),
      );
    }
  }

  @override
  Future<IResult<ChecklistTemplate?, ValidationError>> findById(
    String id,
  ) async {
    try {
      final db = await provider.db;
      final rows = await db.query(
        ChecklistMigration.templatesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return const Success(null);
      final itemRows = await db.query(
        ChecklistMigration.itemsTable,
        where: 'template_id = ?',
        whereArgs: [id],
        orderBy: 'sort_order ASC',
      );
      final mapped = _mapTemplate(rows.first, itemRows);
      return switch (mapped) {
        Success<ChecklistTemplate, ValidationError>(:final value) =>
          Success(value),
        Failure<ChecklistTemplate, ValidationError>(:final value) =>
          Failure(value),
      };
    } on Exception {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.persistence,
          message: 'Não foi possível carregar o modelo de checklist.',
        ),
      );
    }
  }

  @override
  Future<IResult<bool, ValidationError>> delete(String id) async {
    try {
      final db = await provider.db;
      await db.transaction((txn) async {
        await txn.delete(
          ChecklistMigration.itemsTable,
          where: 'template_id = ?',
          whereArgs: [id],
        );
        await txn.delete(
          ChecklistMigration.templatesTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      });
      return const Success(true);
    } on Exception {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.persistence,
          message: 'Não foi possível remover o modelo de checklist.',
        ),
      );
    }
  }

  IResult<ChecklistTemplate, ValidationError> _mapTemplate(
    Map<String, Object?> row,
    List<Map<String, Object?>> itemRows,
  ) {
    final items = <ChecklistItem>[];
    for (final itemRow in itemRows) {
      final itemResult = ChecklistItem.tryCreate(
        id: (itemRow['id'] ?? '') as String,
        title: (itemRow['title'] ?? '') as String,
        isRequired: ((itemRow['is_required'] ?? 1) as int) == 1,
        order: (itemRow['sort_order'] ?? 0) as int,
      );
      if (itemResult.isFailure) return Failure(itemResult.getOrNullFailure()!);
      items.add(itemResult.getOrNull()!);
    }
    return ChecklistTemplate.tryCreate(
      id: (row['id'] ?? '') as String,
      title: (row['title'] ?? '') as String,
      items: items,
    );
  }
}
