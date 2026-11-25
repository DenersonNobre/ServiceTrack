// Tela de cadastro de modelo de checklist (UC-04.09).
//
// SRP: renderizar o rascunho e delegar validação/persistência ao controller.
// Stateless: todo o estado de tela vive no ChecklistTemplateFormController
// (Kortex), inclusive a identidade de cada item em edição.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/ui/app_touch_target.dart';
import 'checklist_template_form_controller.dart';

/// Página de criação de modelo de checklist.
final class ChecklistTemplateFormPage
    extends IKortexPage<ChecklistTemplateFormController> {
  /// Cria a página; [onSaved] é acionado após a persistência.
  const ChecklistTemplateFormPage({super.key, this.onSaved});

  /// Notifica a tela chamadora quando o modelo foi salvo.
  final VoidCallback? onSaved;

  @override
  Widget buildPage(
    BuildContext context,
    ChecklistTemplateFormController controller,
  ) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(controller.isEditing ? 'Editar modelo' : 'Novo modelo'),
      ),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            final drafts = controller.itemDrafts.value;
            final saving = controller.saving.value;
            final error = controller.error.value;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('checklist-template-title'),
                    initialValue: controller.title.value,
                    onChanged: (value) => controller.title.value = value,
                    decoration: _decoration(
                      label: 'Título do modelo',
                      hint: 'Instalação Split',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Itens do checklist',
                    style: TextStyle(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var index = 0; index < drafts.length; index++)
                    Padding(
                      key: ValueKey<String>(drafts[index].id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextFormField(
                        key: Key('checklist-template-item-$index'),
                        initialValue: drafts[index].title,
                        onChanged: (value) =>
                            controller.updateItem(index, value),
                        decoration: _decoration(
                          label: 'Item ${index + 1}',
                        ).copyWith(
                          suffixIcon: IconButton(
                            key: Key('checklist-template-item-remove-$index'),
                            tooltip: 'Remover item',
                            constraints: kMinTouchTargetConstraints,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                            onPressed: saving
                                ? null
                                : () => controller.removeItem(index),
                          ),
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    key: const Key('checklist-template-add-item'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: kMinTouchTargetSize,
                    ),
                    onPressed: saving ? null : () => controller.addItem(),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar item'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error, style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      key: const Key('checklist-template-save'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryAction,
                        foregroundColor: Colors.white,
                        minimumSize: kMinTouchTargetHeight,
                      ),
                      onPressed: saving
                          ? null
                          : () => _save(context, controller),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salvar modelo'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    ChecklistTemplateFormController controller,
  ) async {
    await controller.save();
    if (!context.mounted) return;
    if (controller.saved.value) onSaved?.call();
  }

  InputDecoration _decoration({required String label, String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceCard,
        constraints: const BoxConstraints(minHeight: 48),
        border: const OutlineInputBorder(),
      );
}
