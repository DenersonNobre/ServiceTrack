// Entidades de Modelo de Checklist (UC-04.01).
//
// SRP: validar e encapsular templates reutilizáveis de checklist técnico.
// Não persiste, não formata UI, não acessa I/O.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../ports/checklist_failure_codes.dart';

/// Item individual de um modelo de checklist.
final class ChecklistItem {
  const ChecklistItem._({
    required this.id,
    required this.title,
    required this.isRequired,
    required this.order,
  });

  /// Identificador único do item.
  final String id;

  /// Pergunta/verificação técnica.
  final String title;

  /// Indica se a resposta é obrigatória para conclusão da OS (INV-03).
  final bool isRequired;

  /// Ordem de exibição no checklist.
  final int order;

  /// Cria um item validado.
  static IResult<ChecklistItem, ValidationError> tryCreate({
    required String id,
    required String title,
    bool isRequired = true,
    int order = 0,
  }) {
    if (id.trim().isEmpty) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.invalidItemId,
          message: 'Identificador do item inválido.',
        ),
      );
    }
    final normalized = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.length > 160) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.invalidItemTitle,
          message: 'Informe uma descrição válida para o item (1 a 160 caracteres).',
        ),
      );
    }
    if (order < 0) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.invalidItemOrder,
          message: 'Ordem do item não pode ser negativa.',
        ),
      );
    }
    return Success(
      ChecklistItem._(
        id: id.trim(),
        title: normalized,
        isRequired: isRequired,
        order: order,
      ),
    );
  }
}

/// Modelo reutilizável de checklist vinculado a um tipo de serviço.
final class ChecklistTemplate {
  ChecklistTemplate._({
    required this.id,
    required this.title,
    required List<ChecklistItem> items,
  }) : items = List<ChecklistItem>.unmodifiable(items);

  /// Identificador único do template.
  final String id;

  /// Título do modelo (ex.: "Instalação Split").
  final String title;

  /// Lista imutável de itens ordenados.
  final List<ChecklistItem> items;

  /// Cria um modelo de checklist validado (UC-04.01).
  static IResult<ChecklistTemplate, ValidationError> tryCreate({
    required String id,
    required String title,
    required List<ChecklistItem> items,
  }) {
    if (id.trim().isEmpty) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.invalidTemplateId,
          message: 'Identificador do checklist inválido.',
        ),
      );
    }
    final normalized = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.length > 120) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.invalidTemplateTitle,
          message: 'Informe um título válido para o checklist (1 a 120 caracteres).',
        ),
      );
    }
    if (items.isEmpty) {
      return const Failure(
        ValidationError(
          code: ChecklistFailureCodes.emptyItems,
          message: 'O checklist precisa ter pelo menos um item.',
        ),
      );
    }
    final seenIds = <String>{};
    for (final item in items) {
      if (!seenIds.add(item.id)) {
        return const Failure(
          ValidationError(
            code: ChecklistFailureCodes.duplicateItemId,
            message: 'Existem itens duplicados no checklist.',
          ),
        );
      }
    }
    final sorted = List<ChecklistItem>.of(items)
      ..sort((a, b) => a.order.compareTo(b.order));
    return Success(
      ChecklistTemplate._(
        id: id.trim(),
        title: normalized,
        items: sorted,
      ),
    );
  }
}
