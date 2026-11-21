// Lista de Ordens de Serviço (UC-03.01 base, UC-03.02 filtros).
//
// SRP: renderizar lista de OS, filtros e delegar ações.

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
            final items = controller.filteredItems;
            return Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      for (final f in WorkOrderListFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: ChoiceChip(
                              key: Key('wo-filter-${f.name}'),
                              label: Text(_filterLabel(f)),
                              selected: controller.filter.value == f,
                              onSelected: (_) => controller.filter.value = f,
                              selectedColor: AppColors.primaryAction,
                              labelStyle: TextStyle(
                                color: controller.filter.value == f ? Colors.white : AppColors.gray700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('Nenhuma OS encontrada.'))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final wo = items[i];
                            return ListTile(
                              key: Key('wo-${wo.id}'),
                              title: Text(wo.serviceDescription),
                              subtitle: Text(
                                '${wo.status.code} • ${wo.scheduledAt.toLocal().toString().substring(0, 16)}',
                              ),
                              minTileHeight: 56,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _filterLabel(WorkOrderListFilter f) => switch (f) {
        WorkOrderListFilter.all => 'Todas',
        WorkOrderListFilter.today => 'Hoje',
        WorkOrderListFilter.scheduled => 'Agendadas',
        WorkOrderListFilter.inProgress => 'Em Andamento',
        WorkOrderListFilter.completed => 'Concluídas',
      };
}
