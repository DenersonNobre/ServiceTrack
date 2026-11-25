// Tela de listagem de modelos de checklist (UC-04.01).

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/.index.dart';
import '../../domain/entities/checklist_template.dart';
import 'checklist_template_list_controller.dart';

/// Página de gerenciamento de modelos de checklist.
final class ChecklistTemplateListPage
    extends IKortexPage<ChecklistTemplateListController> {
  /// Cria a página.
  const ChecklistTemplateListPage({
    super.key,
    this.onAdd,
    this.onSelect,
  });

  /// Ação para criar um novo modelo.
  final VoidCallback? onAdd;

  /// Ação ao selecionar um modelo existente.
  final void Function(ChecklistTemplate template)? onSelect;

  @override
  Widget buildPage(
    BuildContext context,
    ChecklistTemplateListController controller,
  ) {
    // ignore: discarded_futures
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Modelos de Checklist'),
      ),
      floatingActionButton: onAdd == null
          ? null
          : FloatingActionButton(
              key: const Key('checklist-template-add'),
              backgroundColor: AppColors.primaryAction,
              foregroundColor: Colors.white,
              onPressed: onAdd,
              child: const Icon(Icons.add),
            ),
      body: KortexWatch(
        builder: (context, _) {
          if (controller.loading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryAction),
            );
          }
          final err = controller.error.value;
          if (err != null) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'Erro ao carregar',
              message: err,
              actionLabel: 'Tentar novamente',
              onAction: controller.load,
            );
          }
          final list = controller.templates.value;
          if (list.isEmpty) {
            return AppEmptyState(
              icon: Icons.checklist_outlined,
              imageAsset: 'assets/images/empty_checklists.png',
              title: 'Nenhum modelo cadastrado',
              message:
                  'Crie modelos reutilizáveis para agilizar seus atendimentos.',
              actionLabel: onAdd == null ? null : 'Novo modelo',
              onAction: onAdd,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final template = list[index];
              return DismissibleTile(
                itemKey: ValueKey<String>(template.id),
                confirmTitle: 'Excluir modelo?',
                confirmMessage:
                    'Deseja realmente excluir o modelo "${template.title}"?',
                onDismissed: () async {
                  await controller.remove(template.id);
                  if (context.mounted) {
                    AppFeedback.showSuccess(
                      context,
                      'Modelo excluído com sucesso',
                    );
                  }
                },
                child: Card(
                  margin: EdgeInsets.zero,
                  color: AppColors.surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    minVerticalPadding: 12,
                    title: Text(
                      template.title,
                      style: const TextStyle(
                        color: AppColors.gray900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${template.items.length} item(ns)',
                      style: const TextStyle(color: AppColors.gray500),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onSelect == null ? null : () => onSelect!(template),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
