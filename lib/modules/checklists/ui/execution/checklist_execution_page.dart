// Página de execução de checklist por OS (UC-04.02/04.06/04.07).
//
// SRP: renderizar itens e delegar persistência ao controller. Não contém regra de negócio.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import 'checklist_execution_controller.dart';
import 'checklist_item_widget.dart';

final class ChecklistExecutionPage
    extends IKortexPage<ChecklistExecutionController> {
  const ChecklistExecutionPage({super.key});

  @override
  Widget buildPage(
    BuildContext context,
    ChecklistExecutionController controller,
  ) {
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: KortexWatch(
          builder: (context, _) =>
              Text(controller.template.value?.title ?? 'Checklist'),
        ),
      ),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.loading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryAction),
              );
            }
            if (controller.error.value != null) {
              return Center(child: Text(controller.error.value!));
            }
            final tpl = controller.template.value;
            if (tpl == null) {
              return const Center(child: Text('Checklist não encontrado.'));
            }
            controller.answers.value;
            controller.savingItemId.value;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tpl.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = tpl.items[i];
                final ans = controller.answers.value[item.id];
                return ChecklistItemWidget(
                  key: Key('check-exec-${item.id}'),
                  title: item.title,
                  selectedStatus: ans?.status,
                  notes: ans?.notes ?? '',
                  enabled: controller.savingItemId.value != item.id,
                  onStatusChanged: (status) async {
                    final res = await controller.setAnswer(
                      itemId: item.id,
                      status: status,
                      notes: controller.answers.value[item.id]?.notes ?? '',
                    );
                    if (!context.mounted) return;
                    if (res.isFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.getOrNullFailure()!.message),
                        ),
                      );
                    }
                  },
                  onNotesChanged: (notes) async {
                    final current = controller.answers.value[item.id];
                    if (current == null) return;
                    final res = await controller.setAnswer(
                      itemId: item.id,
                      status: current.status,
                      notes: notes,
                    );
                    if (!context.mounted) return;
                    if (res.isFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.getOrNullFailure()!.message),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
