// Adapter de composição: prova real de checklist para conclusão de OS (UC-04.07, D-05).
//
// SRP: compor repositórios de checklist para calcular ChecklistCompletionProof.
// Camada de app (composição) - pode depender de módulos.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../../modules/checklists/domain/ports/checklist_answer_repository_port.dart';
import '../../modules/checklists/domain/ports/checklist_template_repository_port.dart';
import '../../modules/work_orders/domain/ports/checklist_proof_port.dart';
import '../../modules/work_orders/domain/value_objects/checklist_completion_proof.dart';

/// Calcula prova real de checklist a partir de template + respostas.
final class ChecklistProofAdapter implements IChecklistProofPort {
  ChecklistProofAdapter({
    required this.templateRepository,
    required this.answerRepository,
  });

  final IChecklistTemplateRepositoryPort templateRepository;
  final IChecklistAnswerRepositoryPort answerRepository;

  @override
  Future<IResult<ChecklistCompletionProof, ValidationError>> getProof({
    required String workOrderId,
    required String? templateId,
  }) async {
    final tplId = templateId?.trim();
    if (tplId == null || tplId.isEmpty) {
      return ChecklistCompletionProof.tryCreate(mandatoryTotal: 0, answeredMandatory: 0);
    }

    final templateResult = await templateRepository.findById(tplId);
    switch (templateResult) {
      case Failure(:final value):
        return Failure(value);
      case Success(:final value):
        final template = value;
        if (template == null) {
          return const Failure(
            ValidationError(
              code: 'ERR_CHECKLIST_NAO_ENCONTRADO',
              message: 'Modelo de checklist não encontrado.',
            ),
          );
        }
        final answersResult = await answerRepository.findByWorkOrder(workOrderId);
        switch (answersResult) {
          case Failure(:final value):
            return Failure(value);
          case Success(:final value):
            final answeredIds = value.map((a) => a.itemId).toSet();
            final requiredItems = template.items.where((i) => i.isRequired).toList();
            final answeredRequired =
                requiredItems.where((i) => answeredIds.contains(i.id)).length;
            return ChecklistCompletionProof.tryCreate(
              mandatoryTotal: requiredItems.length,
              answeredMandatory: answeredRequired,
            );
        }
    }
  }
}
