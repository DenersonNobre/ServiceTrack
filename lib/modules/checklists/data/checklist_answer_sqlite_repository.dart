// Repositório SQLite de respostas de checklist por OS (UC-04.06).
//
// SRP: persistir e carregar respostas de checklist por work_order_id.
// Não valida regra de negócio de completude (domínio).

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:dnolib/sqlite/sqlite.dart';

import '../domain/entities/checklist_answer.dart';
import '../domain/ports/checklist_answer_repository_port.dart';
import '../domain/ports/checklist_failure_codes.dart';
import 'checklist_migration.dart';

/// Adapter SQLite da porta [IChecklistAnswerRepositoryPort].
final class ChecklistAnswerSqliteRepository
    implements IChecklistAnswerRepositoryPort {
  /// Cria o repositório sobre [provider].
  ChecklistAnswerSqliteRepository({required this.provider});

  /// Provider SQLite da `dnolib`.
  final SqliteProvider provider;

  @override
  Future<IResult<ChecklistAnswer, ValidationError>> save(
    ChecklistAnswer answer,
  ) async {
    try {
      final db = await provider.db;
      await db.execute(
        '''
        INSERT INTO ${ChecklistMigration.answersTable}
          (work_order_id, item_id, status, notes, answered_at_utc)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(work_order_id, item_id) DO UPDATE SET
          status = excluded.status,
          notes = excluded.notes,
          answered_at_utc = excluded.answered_at_utc
        ''',
        [
          answer.workOrderId,
          answer.itemId,
          answer.status.name,
          answer.notes,
          answer.answeredAtUtc.toIso8601String(),
        ],
      );
      return Success(answer);
    } on Exception {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.persistence,
          message: 'Não foi possível salvar a resposta do checklist.',
        ),
      );
    }
  }

  @override
  Future<IResult<List<ChecklistAnswer>, ValidationError>> findByWorkOrder(
    String workOrderId,
  ) async {
    try {
      final db = await provider.db;
      final rows = await db.query(
        ChecklistMigration.answersTable,
        where: 'work_order_id = ?',
        whereArgs: [workOrderId],
        orderBy: 'answered_at_utc ASC, item_id ASC',
      );
      final result = <ChecklistAnswer>[];
      for (final row in rows) {
        final mapped = _mapAnswer(row);
        if (mapped.isFailure) return Failure(mapped.getOrNullFailure()!);
        result.add(mapped.getOrNull()!);
      }
      return Success(result);
    } on Exception {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.persistence,
          message: 'Não foi possível carregar as respostas do checklist.',
        ),
      );
    }
  }

  IResult<ChecklistAnswer, ValidationError> _mapAnswer(
    Map<String, Object?> row,
  ) {
    final statusName = (row['status'] ?? '') as String;
    final status = ChecklistAnswerStatus.values
        .where((e) => e.name == statusName)
        .firstOrNull;
    if (status == null) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.persistence,
          message: 'Resposta de checklist com status inválido.',
        ),
      );
    }
    final answeredAtRaw = (row['answered_at_utc'] ?? '') as String;
    final answeredAt = DateTime.tryParse(answeredAtRaw);
    if (answeredAt == null) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.persistence,
          message: 'Resposta de checklist com data inválida.',
        ),
      );
    }
    return ChecklistAnswer.tryCreate(
      workOrderId: (row['work_order_id'] ?? '') as String,
      itemId: (row['item_id'] ?? '') as String,
      status: status,
      notes: (row['notes'] ?? '') as String,
      answeredAtUtc: answeredAt.toUtc(),
    );
  }
}
