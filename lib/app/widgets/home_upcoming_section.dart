import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../modules/work_orders/domain/value_objects/work_order.dart';
import '../../modules/work_orders/domain/value_objects/work_order_status.dart';

/// Seção com a lista das próximas visitas da Home.
final class HomeUpcomingSection extends StatelessWidget {
  /// Cria a seção de próximas visitas com lista ou estado vazio.
  const HomeUpcomingSection({
    super.key,
    required this.upcoming,
    required this.onOpenWorkOrders,
  });

  final List<WorkOrder> upcoming;
  final VoidCallback onOpenWorkOrders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: onOpenWorkOrders,
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          const HomeUpcomingEmptyCard()
        else
          ...upcoming.map(
            (wo) => HomeUpcomingCard(workOrder: wo, onTap: onOpenWorkOrders),
          ),
      ],
    );
  }
}

/// Card de visita agendada / em andamento.
final class HomeUpcomingCard extends StatelessWidget {
  /// Cria o card para uma ordem de serviço na agenda.
  const HomeUpcomingCard({
    super.key,
    required this.workOrder,
    required this.onTap,
  });

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
                HomeStatusChip(status: workOrder.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip indicador de status da ordem de serviço.
final class HomeStatusChip extends StatelessWidget {
  /// Cria o chip de status colorido.
  const HomeStatusChip({super.key, required this.status});

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

/// Card informativo exibido quando não há visitas agendadas.
final class HomeUpcomingEmptyCard extends StatelessWidget {
  /// Cria o card de estado vazio da agenda.
  const HomeUpcomingEmptyCard({super.key});

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
