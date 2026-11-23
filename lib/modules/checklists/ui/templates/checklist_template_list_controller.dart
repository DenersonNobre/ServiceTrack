// Controller de listagem de modelos de checklist (UC-04.01).
//
// SRP: carregar e remover modelos de checklist expondo sinais readonly.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../domain/entities/checklist_template.dart';
import '../../domain/ports/checklist_template_repository_port.dart';

/// Controller Kortex da lista de modelos de checklist.
final class ChecklistTemplateListController extends IKortexController {
  /// Cria o controller com [repository].
  ChecklistTemplateListController({required this.repository}) {
    autoDispose(_loading);
    autoDispose(_templates);
    autoDispose(_error);
  }

  /// Porta de persistência.
  final IChecklistTemplateRepositoryPort repository;

  final KortexSignal<bool> _loading = KortexSignal<bool>(true);
  final KortexSignal<List<ChecklistTemplate>> _templates =
      KortexSignal<List<ChecklistTemplate>>(const []);
  final KortexSignal<String?> _error = KortexSignal<String?>(null);

  bool _loaded = false;

  /// Estado de carregamento (somente leitura).
  IKortexReadonlySignal<bool> get loading => _loading;

  /// Lista de modelos carregados (somente leitura).
  IKortexReadonlySignal<List<ChecklistTemplate>> get templates => _templates;

  /// Mensagem de erro, se houver (somente leitura).
  IKortexReadonlySignal<String?> get error => _error;

  /// Carrega uma única vez na montagem inicial.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    await load();
  }

  /// Recarrega a lista de modelos do repositório.
  Future<void> load() async {
    _loading.value = true;
    _error.value = null;
    final result = await repository.findAll();
    _loading.value = false;
    switch (result) {
      case Success<List<ChecklistTemplate>, ValidationError>(:final value):
        _templates.value = value;
      case Failure<List<ChecklistTemplate>, ValidationError>(:final value):
        _error.value = value.message;
    }
  }

  /// Remove um modelo e atualiza a listagem.
  Future<void> remove(String id) async {
    final result = await repository.delete(id);
    switch (result) {
      case Success<bool, ValidationError>():
        await load();
      case Failure<bool, ValidationError>(:final value):
        _error.value = value.message;
    }
  }
}
