import 'package:flutter/material.dart';

import '../../domain/models/home_dashboard_data.dart';

/// Grade de KPIs operacionais do dia na Home.
final class HomeKpiGrid extends StatelessWidget {
  /// Cria a grade de 4 cards de KPI com callback para abrir ordens de serviço.
  const HomeKpiGrid({
    super.key,
    required this.data,
    required this.onOpenWorkOrders,
  });

  final HomeDashboardData data;
  final VoidCallback onOpenWorkOrders;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HomeKpiCard(
                key: const Key('home-kpi-scheduled-today'),
                icon: Icons.today_outlined,
                label: 'Agendadas hoje',
                value: '${data.scheduledToday}',
                onTap: onOpenWorkOrders,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HomeKpiCard(
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
              child: HomeKpiCard(
                key: const Key('home-kpi-paused'),
                icon: Icons.pause_circle_outline,
                label: 'Pausadas',
                value: '${data.paused}',
                onTap: onOpenWorkOrders,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HomeKpiCard(
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

/// Card individual de KPI com alvo de toque acessível.
final class HomeKpiCard extends StatelessWidget {
  /// Cria um card de KPI com ícone, rótulo, valor numérico e toque interativo.
  const HomeKpiCard({
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
