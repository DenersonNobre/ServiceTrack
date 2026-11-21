// Lista de Ordens de Serviço (UC-03.01 base, UC-03.02 filtros, UC-03.03 check-in).
//
// SRP: renderizar lista de OS, filtros e ações de check-in. Não contém regra de negócio.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/value_objects/check_in_bypass_reason.dart';
import '../../domain/value_objects/work_order_status.dart';
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
            final startingId = controller.startingId.value;
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
                            final isStarting = startingId == wo.id;
                            return ListTile(
                              key: Key('wo-${wo.id}'),
                              title: Text(wo.serviceDescription),
                              subtitle: Text(
                                '${wo.status.code} • ${wo.scheduledAt.toLocal().toString().substring(0, 16)}',
                              ),
                              minTileHeight: 56,
                              trailing: (wo.status == WorkOrderStatus.scheduled ||
                                      wo.status == WorkOrderStatus.inProgress)
                                  ? isStarting
                                      ? const SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        )
                                      : PopupMenuButton<String>(
                                          key: Key('wo-actions-${wo.id}'),
                                          icon: const Icon(Icons.more_vert),
                                          tooltip: 'Ações',
                                          onSelected: (v) {
                                            if (v == 'start') _startService(context, controller, wo.id);
                                            if (v == 'cancel') _cancelWorkOrder(context, controller, wo.id);
                                          },
                                          itemBuilder: (_) => [
                                            if (wo.status == WorkOrderStatus.scheduled)
                                              const PopupMenuItem(
                                                value: 'start',
                                                child: Text('Iniciar atendimento'),
                                              ),
                                            const PopupMenuItem(
                                              value: 'cancel',
                                              child: Text('Cancelar OS'),
                                            ),
                                          ],
                                        )
                                  : null,
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

  Future<void> _startService(
    BuildContext context,
    WorkOrderListController controller,
    String workOrderId,
  ) async {
    final result = await controller.startService(workOrderId);
    if (!context.mounted) return;
    if (result.isSuccess) return;
    final err = result.getOrNullFailure()!;
    final reason = _bypassReasonForCode(err.code);
    if (reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message)));
      return;
    }
    final bypassed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Localização indisponível'),
        content: Text(
          '${err.message}\n\nDeseja registrar o check-in sem GPS? '
          'Este bypass será auditado com motivo explícito.',
        ),
        actions: [
          if (err.code == 'ERR_LOCALIZACAO_PERMISSAO_NEGADA_PERMANENTE' ||
              err.code == 'ERR_LOCALIZACAO_SERVICO_DESLIGADO')
            TextButton(
              onPressed: () async {
                if (err.code == 'ERR_LOCALIZACAO_PERMISSAO_NEGADA_PERMANENTE') {
                  await Geolocator.openAppSettings();
                } else {
                  await Geolocator.openLocationSettings();
                }
              },
              child: const Text('Abrir configurações'),
            ),
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            key: const Key('wo-bypass-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryAction),
            child: const Text('Registrar bypass'),
          ),
        ],
      ),
    );
    if (bypassed != true || !context.mounted) return;
    final bypassResult = await controller.startServiceWithBypass(workOrderId, reason);
    if (!context.mounted) return;
    if (bypassResult.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bypassResult.getOrNullFailure()!.message)),
      );
    }
  }

  Future<void> _cancelWorkOrder(
    BuildContext context,
    WorkOrderListController controller,
    String workOrderId,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar OS'),
        content: TextField(
          key: const Key('wo-cancel-reason'),
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Justificativa',
            hintText: 'Informe o motivo do cancelamento',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Voltar')),
          FilledButton(
            key: const Key('wo-cancel-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancelar OS'),
          ),
        ],
      ),
    );
    final reason = reasonController.text;
    reasonController.dispose();
    if (confirmed != true || !context.mounted) return;
    final result = await controller.cancel(workOrderId, reason);
    if (!context.mounted) return;
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.getOrNullFailure()!.message)),
      );
    }
  }

  CheckInBypassReason? _bypassReasonForCode(String code) => switch (code) {
        'ERR_LOCALIZACAO_PERMISSAO_NEGADA' => CheckInBypassReason.permissionDenied,
        'ERR_LOCALIZACAO_PERMISSAO_NEGADA_PERMANENTE' =>
          CheckInBypassReason.permissionDeniedPermanently,
        'ERR_LOCALIZACAO_SERVICO_DESLIGADO' => CheckInBypassReason.gpsUnavailable,
        'ERR_LOCALIZACAO_TIMEOUT' => CheckInBypassReason.timeout,
        'ERR_LOCALIZACAO_INDISPONIVEL' => CheckInBypassReason.gpsUnavailable,
        'ERR_LOCALIZACAO_DADOS_INVALIDOS' => CheckInBypassReason.gpsUnavailable,
        _ => null,
      };

  String _filterLabel(WorkOrderListFilter f) => switch (f) {
        WorkOrderListFilter.all => 'Todas',
        WorkOrderListFilter.today => 'Hoje',
        WorkOrderListFilter.scheduled => 'Agendadas',
        WorkOrderListFilter.inProgress => 'Em Andamento',
        WorkOrderListFilter.completed => 'Concluídas',
      };
}
