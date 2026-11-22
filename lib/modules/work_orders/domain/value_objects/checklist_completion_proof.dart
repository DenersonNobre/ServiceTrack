// Value Object Prova de completude do checklist (UC-03.05, INV-SEC-22).
//
// SRP: representar prova fail-closed de que checklist obrigatório está completo.
// Não persiste, não renderiza UI.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../ports/work_order_failure_codes.dart';

/// Prova de completude de checklist obrigatório.
final class ChecklistCompletionProof {
  const ChecklistCompletionProof._({
    required this.mandatoryTotal,
    required this.answeredMandatory,
  });

  final int mandatoryTotal;
  final int answeredMandatory;

  static IResult<ChecklistCompletionProof, ValidationError> tryCreate({
    required int mandatoryTotal,
    required int answeredMandatory,
  }) {
    if (mandatoryTotal < 0 || answeredMandatory < 0 || answeredMandatory > mandatoryTotal) {
      return const Failure(ValidationError(
        code: WorkOrderFailureCodes.checklistIncomplete,
        message: 'Checklist obrigatório incompleto.',
      ));
    }
    if (answeredMandatory != mandatoryTotal) {
      return const Failure(ValidationError(
        code: WorkOrderFailureCodes.checklistIncomplete,
        message: 'Checklist obrigatório incompleto.',
      ));
    }
    return Success(ChecklistCompletionProof._(
      mandatoryTotal: mandatoryTotal,
      answeredMandatory: answeredMandatory,
    ));
  }

  @override
  String toString() => 'ChecklistCompletionProof(total: $mandatoryTotal, answered: $answeredMandatory)';
}
