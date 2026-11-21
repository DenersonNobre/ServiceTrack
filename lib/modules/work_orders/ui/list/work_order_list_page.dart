// Lista de Ordens de Serviço (UC-03.01 base).
//
// SRP: renderizar lista de OS e delegar ações.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import 'work_order_list_controller.dart';

final class WorkOrderListPage extends IKortexPage<WorkOrderListController> {
  const WorkOrderListPage({super.key, this.onAdd});
  final VoidCallback? onAdd;

  @override
  Widget buildPage(BuildContext context, WorkOrderListController controller) {
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Ordens de Serviço')),
      floatingActionButton: FloatingActionButton(
        key: const Key('wo-add'),
        backgroundColor: AppColors.primaryAction,
        foregroundColor: Colors.white,
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryAction));
            }
            if (controller.error.value != null) return Center(child: Text(controller.error.value!));
            final items = controller.items.value;
            if (items.isEmpty) return const Center(child: Text('Nenhuma OS cadastrada.'));
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final wo = items[i];
                return ListTile(
                  key: Key('wo-${wo.id}'),
                  title: Text(wo.serviceDescription),
                  subtitle: Text('${wo.status.code} • ${wo.scheduledAt.toLocal().toString().substring(0, 16)}'),
                  minTileHeight: 56,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
