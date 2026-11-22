// Entidade de resposta de item de checklist e validação INV-03 / INV-06 (UC-04.02).
//
// SRP: validar resposta tri-estado de checklist e completude obrigatória da OS.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../ports/checklist_failure_codes.dart';
import 'checklist_template.dart';

/// Estado tri-estado de um item de checklist técnico.
enum ChecklistAnswerStatus {
  /// Item verificado e em conformidade.
  conforme,

  /// Item apresenta não conformidade técnica.
  naoConforme,

  /// Item não aplicável ao atendimento.
  naoAplica,
}

/// Resposta registrada para um item de checklist em uma OS.
final class ChecklistAnswer {
  const ChecklistAnswer._({
    required this.workOrderId,
    required this.itemId,
    required this.status,
    required this.notes,
    required this.answeredAtUtc,
  });

  /// Identificador da Ordem de Serviço.
  final String workOrderId;

  /// Identificador do [ChecklistItem].
  final String itemId;

  /// Situação marcada pelo técnico.
  final ChecklistAnswerStatus status;

  /// Observação técnica (opcional ou descritiva de não conformidade).
  final String notes;

  /// Momento UTC da resposta.
  final DateTime answeredAtUtc;

  /// Cria uma resposta validando imutabilidade da OS (INV-06).
  static IResult<ChecklistAnswer, ValidationError> tryCreate({
    required String workOrderId,
    required String itemId,
    required ChecklistAnswerStatus status,
    String notes = '',
    bool isWorkOrderMutable = true,
    DateTime? answeredAtUtc,
  }) {
    if (!isWorkOrderMutable) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.workOrderImmutable,
          message: 'Ordem de Serviço concluída ou cancelada não pode ser alterada.',
        ),
      );
    }
    if (workOrderId.trim().isEmpty || itemId.trim().isEmpty) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.invalidAnswer,
          message: 'Identificadores da OS e do item são obrigatórios.',
        ),
      );
    }
    final normalizedNotes = notes.trim();
    if (normalizedNotes.length > 500) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.notesTooLong,
          message: 'Observação excede o limite de 500 caracteres.',
        ),
      );
    }
    return Success(
      ChecklistAnswer._(
        workOrderId: workOrderId.trim(),
        itemId: itemId.trim(),
        status: status,
        notes: normalizedNotes,
        answeredAtUtc: (answeredAtUtc ?? DateTime.now()).toUtc(),
      ),
    );
  }
}

/// Valida a completude obrigatória do checklist antes do fechamento da OS (INV-03).
IResult<bool, ValidationError> validateChecklistCompleteness({
  required ChecklistTemplate template,
  required List<ChecklistAnswer> answers,
}) {
  final answeredIds = answers.map((a) => a.itemId).toSet();
  for (final item in template.items) {
    if (item.isRequired && !answeredIds.contains(item.id)) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.incomplete,
          message: 'Responda todos os itens obrigatórios do checklist antes de concluir.',
        ),
      );
    }
  }
  return const Success(true);
}
