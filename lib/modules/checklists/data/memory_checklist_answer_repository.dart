// Repositório em memória de respostas de checklist (testes e fallback).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../domain/entities/checklist_answer.dart';
import '../domain/ports/checklist_answer_repository_port.dart';

/// Implementação em memória de [IChecklistAnswerRepositoryPort].
final class MemoryChecklistAnswerRepository
    implements IChecklistAnswerRepositoryPort {
  final Map<String, Map<String, ChecklistAnswer>> _byOrder =
      <String, Map<String, ChecklistAnswer>>{};

  @override
  Future<IResult<ChecklistAnswer, ValidationError>> save(
    ChecklistAnswer answer,
  ) async {
    final map = _byOrder.putIfAbsent(
      answer.workOrderId,
      () => <String, ChecklistAnswer>{},
    );
    map[answer.itemId] = answer;
    return Success(answer);
  }

  @override
  Future<IResult<List<ChecklistAnswer>, ValidationError>> findByWorkOrder(
    String workOrderId,
  ) async {
    final map = _byOrder[workOrderId];
    return Success(map == null ? const [] : map.values.toList());
  }
}
