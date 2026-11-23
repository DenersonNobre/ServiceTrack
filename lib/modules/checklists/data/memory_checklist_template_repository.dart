// Repositório em memória de modelos de checklist (testes e fallback).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../domain/entities/checklist_template.dart';
import '../domain/ports/checklist_template_repository_port.dart';

/// Implementação em memória de [IChecklistTemplateRepositoryPort].
final class MemoryChecklistTemplateRepository
    implements IChecklistTemplateRepositoryPort {
  final Map<String, ChecklistTemplate> _items = <String, ChecklistTemplate>{};

  @override
  Future<IResult<ChecklistTemplate, ValidationError>> save(
    ChecklistTemplate template,
  ) async {
    _items[template.id] = template;
    return Success(template);
  }

  @override
  Future<IResult<List<ChecklistTemplate>, ValidationError>> findAll() async {
    final list = _items.values.toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return Success(list);
  }

  @override
  Future<IResult<ChecklistTemplate?, ValidationError>> findById(
    String id,
  ) async =>
      Success(_items[id]);

  @override
  Future<IResult<bool, ValidationError>> delete(String id) async {
    _items.remove(id);
    return const Success(true);
  }
}
