// Porta de persistência de modelos de checklist (DIP / UC-04.01).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../entities/checklist_template.dart';

/// Contrato de persistência local de [ChecklistTemplate].
abstract interface class IChecklistTemplateRepositoryPort {
  /// Salva ou atualiza um template e seus itens.
  Future<IResult<ChecklistTemplate, ValidationError>> save(
    ChecklistTemplate template,
  );

  /// Lista todos os templates ordenados por título.
  Future<IResult<List<ChecklistTemplate>, ValidationError>> findAll();

  /// Busca um template por identificador.
  Future<IResult<ChecklistTemplate?, ValidationError>> findById(String id);

  /// Remove um template e seus itens.
  Future<IResult<bool, ValidationError>> delete(String id);
}
