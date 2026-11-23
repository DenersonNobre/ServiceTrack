// Controller do cadastro de modelo de checklist (UC-04.09).
//
// SRP: orquestrar o rascunho e a persistência de um template reutilizável.
// Não renderiza UI e não duplica regra de negócio: título e itens são
// validados pelas entidades do domínio (ChecklistTemplate/ChecklistItem).

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/checklist_template.dart';
import '../../domain/ports/checklist_template_repository_port.dart';

/// Rascunho de item em edição.
///
/// Carrega identidade própria para que a lista editável preserve o estado de
/// cada campo ao inserir/remover vizinhos (`ValueKey(draft.id)`).
final class ChecklistItemDraft {
  /// Cria um rascunho imutável.
  const ChecklistItemDraft({required this.id, required this.title});

  /// Identidade estável durante toda a edição.
  final String id;

  /// Texto atual do rascunho.
  final String title;

  /// Devolve cópia com novo texto.
  ChecklistItemDraft copyWith({String? title}) =>
      ChecklistItemDraft(id: id, title: title ?? this.title);
}

/// Controller Kortex do formulário de modelo de checklist.
final class ChecklistTemplateFormController extends IKortexController {
  /// Cria o controller sobre [repository].
  ChecklistTemplateFormController({required this.repository});

  /// Porta de persistência.
  final IChecklistTemplateRepositoryPort repository;

  /// Título do modelo em edição.
  final KortexSignal<String> title = KortexSignal<String>('');

  /// Rascunhos de itens, na ordem exibida.
  final KortexSignal<List<ChecklistItemDraft>> itemDrafts =
      KortexSignal<List<ChecklistItemDraft>>(const <ChecklistItemDraft>[]);

  /// Indica gravação em andamento.
  final KortexSignal<bool> saving = KortexSignal<bool>(false);

  /// Mensagem de erro da última tentativa.
  final KortexSignal<String?> error = KortexSignal<String?>(null);

  /// Indica que o modelo foi persistido.
  final KortexSignal<bool> saved = KortexSignal<bool>(false);

  String? _lastFailureCode;

  /// Código de falha da última tentativa (equivale ao `code` do domínio).
  String? get lastFailureCode => _lastFailureCode;

  /// Adiciona um rascunho de item (vazio por padrão).
  void addItem([String text = '']) {
    itemDrafts.value = <ChecklistItemDraft>[
      ...itemDrafts.value,
      ChecklistItemDraft(id: const Uuid().v4(), title: text),
    ];
  }

  /// Atualiza o texto do rascunho na posição [index].
  void updateItem(int index, String text) {
    if (index < 0 || index >= itemDrafts.value.length) return;
    final next = <ChecklistItemDraft>[...itemDrafts.value];
    next[index] = next[index].copyWith(title: text);
    itemDrafts.value = next;
  }

  /// Remove o rascunho na posição [index].
  void removeItem(int index) {
    if (index < 0 || index >= itemDrafts.value.length) return;
    final next = <ChecklistItemDraft>[...itemDrafts.value];
    next.removeAt(index);
    itemDrafts.value = next;
  }

  /// Textos preenchidos, já aparados e sem itens em branco.
  List<String> get _filledTitles => itemDrafts.value
      .map((draft) => draft.title.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  /// Valida pelo domínio e persiste o modelo.
  Future<void> save() async {
    if (saving.value) return;
    saving.value = true;
    error.value = null;
    _lastFailureCode = null;

    final id = const Uuid().v4();
    final filled = _filledTitles;

    final items = <ChecklistItem>[];
    for (var index = 0; index < filled.length; index++) {
      final item = ChecklistItem.tryCreate(
        id: '$id-$index',
        title: filled[index],
        order: index,
      );
      switch (item) {
        case Failure<ChecklistItem, ValidationError>(:final value):
          saving.value = false;
          _lastFailureCode = value.code;
          error.value = value.message;
          return;
        case Success<ChecklistItem, ValidationError>(:final value):
          items.add(value);
      }
    }

    final draft = ChecklistTemplate.tryCreate(
      id: id,
      title: title.value,
      items: items,
    );
    switch (draft) {
      case Failure<ChecklistTemplate, ValidationError>(:final value):
        saving.value = false;
        _lastFailureCode = value.code;
        error.value = value.message;
        return;
      case Success<ChecklistTemplate, ValidationError>(:final value):
        final persisted = await repository.save(value);
        saving.value = false;
        switch (persisted) {
          case Success<ChecklistTemplate, ValidationError>():
            saved.value = true;
          case Failure<ChecklistTemplate, ValidationError>(:final value):
            _lastFailureCode = value.code;
            error.value = value.message;
        }
    }
  }

  @override
  void onDispose() {
    title.dispose();
    itemDrafts.dispose();
    saving.dispose();
    error.dispose();
    saved.dispose();
  }
}
