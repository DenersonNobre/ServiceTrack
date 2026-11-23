// Tela inicial do ServiceTrack (dashboard operacional + navegação).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kortex/kortex.dart';

import '../modules/work_orders/domain/value_objects/work_order.dart';
import '../modules/work_orders/domain/value_objects/work_order_status.dart';
import 'home_dashboard_controller.dart';

/// Tela principal após desbloqueio do aplicativo.
final class HomePage extends StatelessWidget {
  /// Cria a tela inicial com callbacks de navegação dos módulos.
  const HomePage({
    super.key,
    required this.controller,
    required this.onProfile,
    required this.onCustomers,
    required this.onWorkOrders,
    required this.onNewWorkOrder,
    required this.onChecklists,
    required this.onSettings,
  });

  final HomeDashboardController controller;
  final VoidCallback onProfile;
  final VoidCallback onCustomers;
  final VoidCallback onWorkOrders;
  final VoidCallback onNewWorkOrder;
  final VoidCallback onChecklists;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    controller.ensureLoaded();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ServiceTrack')),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: scheme.primaryContainer),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 40,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ServiceTrack',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestão de visitas técnicas',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
              _DrawerItem(
                key: const Key('drawer-home'),
                icon: Icons.home_outlined,
                label: 'Início',
                onTap: () => Navigator.of(context).pop(),
              ),
              const Divider(height: 1),
              _DrawerItem(
                key: const Key('drawer-customers'),
                icon: Icons.people_outline,
                label: 'Clientes',
                onTap: () => _navigate(context, onCustomers),
              ),
              _DrawerItem(
                key: const Key('drawer-work-orders'),
                icon: Icons.assignment_outlined,
                label: 'Ordens de Serviço',
                onTap: () => _navigate(context, onWorkOrders),
              ),
              _DrawerItem(
                key: const Key('drawer-checklists'),
                icon: Icons.checklist_outlined,
                label: 'Modelos de Checklist',
                onTap: () => _navigate(context, onChecklists),
              ),
              const Divider(height: 1),
              _DrawerItem(
                key: const Key('drawer-profile'),
                icon: Icons.person_outline,
                label: 'Perfil comercial',
                onTap: () => _navigate(context, onProfile),
              ),
              _DrawerItem(
                key: const Key('drawer-settings'),
                icon: Icons.settings_outlined,
                label: 'Configurações',
                onTap: () => _navigate(context, onSettings),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('home-new-work-order'),
        onPressed: onNewWorkOrder,
        icon: const Icon(Icons.add),
        label: const Text('Nova OS'),
      ),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final err = controller.error.value;
            if (err != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(err, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => controller.load(),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final data = controller.data.value;
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Text(
                    'Painel do dia',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _KpiGrid(data: data, onOpenWorkOrders: onWorkOrders),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Próximas visitas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        key: const Key('home-see-all-work-orders'),
                        onPressed: onWorkOrders,
                        child: const Text('Ver todas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (data.upcoming.isEmpty)
                    const _EmptyUpcoming()
                  else
                    ...data.upcoming.map(
                      (wo) => _UpcomingCard(workOrder: wo, onTap: onWorkOrders),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigate(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }
}

final class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data, required this.onOpenWorkOrders});
  final HomeDashboardData data;
  final VoidCallback onOpenWorkOrders;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                key: const Key('home-kpi-scheduled-today'),
                icon: Icons.today_outlined,
                label: 'Agendadas hoje',
                value: '${data.scheduledToday}',
                onTap: onOpenWorkOrders,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                key: const Key('home-kpi-in-progress'),
                icon: Icons.play_circle_outline,
                label: 'Em andamento',
                value: '${data.inProgress}',
                onTap: onOpenWorkOrders,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                key: const Key('home-kpi-paused'),
                icon: Icons.pause_circle_outline,
                label: 'Pausadas',
                value: '${data.paused}',
                onTap: onOpenWorkOrders,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                key: const Key('home-kpi-completed-today'),
                icon: Icons.check_circle_outline,
                label: 'Concluídas hoje',
                value: '${data.completedToday}',
                onTap: onOpenWorkOrders,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _KpiCard extends StatelessWidget {
  const _KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: key == null ? null : Key('${(key as ValueKey<String>).value}-tap'),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(height: 8),
                Text(value, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 2),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.workOrder, required this.onTap});
  final WorkOrder workOrder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final local = workOrder.scheduledAt.toLocal();
    final dateFmt = DateFormat('dd/MM HH:mm');
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workOrder.serviceDescription,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFmt.format(local),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(status: workOrder.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final WorkOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      WorkOrderStatus.scheduled => ('Agendada', Colors.blueGrey),
      WorkOrderStatus.inProgress => ('Em andamento', Colors.teal),
      WorkOrderStatus.paused => ('Pausada', Colors.orange),
      WorkOrderStatus.completed => ('Concluída', Colors.green),
      WorkOrderStatus.cancelled => ('Cancelada', Colors.grey),
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

final class _EmptyUpcoming extends StatelessWidget {
  const _EmptyUpcoming();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma visita agendada',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Crie uma nova OS para aparecer aqui.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      minTileHeight: 48,
      onTap: onTap,
    );
  }
}
