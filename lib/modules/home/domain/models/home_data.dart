// Modelo de dados do resumo operacional da home (MVP).
//
// SRP: carregar OS e expor KPIs/agenda do dia para a home.
// Não renderiza UI, não persiste, não navega.

import '../../../work_orders/domain/value_objects/work_order.dart';

/// Resumo operacional exibido na home.
final class HomeData {
  const HomeData({
    required this.scheduledToday,
    required this.inProgress,
    required this.paused,
    required this.completedToday,
    required this.upcoming,
  });

  final int scheduledToday;
  final int inProgress;
  final int paused;
  final int completedToday;
  final List<WorkOrder> upcoming;

  static const empty = HomeData(
    scheduledToday: 0,
    inProgress: 0,
    paused: 0,
    completedToday: 0,
    upcoming: <WorkOrder>[],
  );
}
