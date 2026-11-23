// Porta de prova de completude de checklist para conclusão de OS (UC-04.07, D-05).
//
// SRP: abstrair cálculo da prova real de checklist (DIP).
// Não acessa SQLite/UI diretamente.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../value_objects/checklist_completion_proof.dart';

/// Contrato para obter prova real de completude de checklist.
abstract interface class IChecklistProofPort {
  /// Calcula prova para [workOrderId] dado [templateId] vinculado.
  ///
  /// Se [templateId] for null/vazio, aplica política [requireTemplate]:
  /// quando true, falha fail-closed; quando false, retorna prova 0/0.
  Future<IResult<ChecklistCompletionProof, ValidationError>> getProof({
    required String workOrderId,
    required String? templateId,
    bool requireTemplate = true,
  });
}
