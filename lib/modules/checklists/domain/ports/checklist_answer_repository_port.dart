// Porta de persistência de respostas de checklist por OS (DIP / UC-04.02).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../entities/checklist_answer.dart';

/// Contrato de persistência de [ChecklistAnswer].
abstract interface class IChecklistAnswerRepositoryPort {
  /// Salva ou atualiza a resposta de um item da OS.
  Future<IResult<ChecklistAnswer, ValidationError>> save(
    ChecklistAnswer answer,
  );

  /// Lista todas as respostas registradas para [workOrderId].
  Future<IResult<List<ChecklistAnswer>, ValidationError>> findByWorkOrder(
    String workOrderId,
  );
}
