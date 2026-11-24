// Controller do dashboard da home (MVP operacional).
//
// SRP: carregar OS e expor KPIs/agenda do dia para a home. Não renderiza UI,
// não persiste, não navega.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../modules/work_orders/domain/ports/work_order_repository_port.dart';
import '../modules/work_orders/domain/value_objects/work_order.dart';
import '../modules/work_orders/domain/value_objects/work_order_status.dart';

/// Resumo operacional exibido na home.
final class HomeDashboardData {
  const HomeDashboardData({
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

  static const empty = HomeDashboardData(
    scheduledToday: 0,
    inProgress: 0,
    paused: 0,
    completedToday: 0,
    upcoming: <WorkOrder>[],
  );
}

/// Controller Kortex do dashboard da home.
final class HomeDashboardController extends IKortexController {
  HomeDashboardController({required this.repository});

  final IWorkOrderRepositoryPort repository;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  final KortexSignal<HomeDashboardData> data = KortexSignal<HomeDashboardData>(
    HomeDashboardData.empty,
  );

  bool _loaded = false;
  bool _isDisposed = false;

  /// Indica se o controller já foi descartado.
  @override
  bool get isDisposed => _isDisposed;

  /// Carrega dados na primeira exibição.
  void ensureLoaded() {
    if (_isDisposed || _loaded) return;
    _loaded = true;
    // ignore: discarded_futures
    load();
  }

  /// Recarrega KPIs e próximas visitas.
  Future<void> load() async {
    if (_isDisposed) return;
    debugPrint('[HomeDashboardController] load() started');
    loading.value = true;
    error.value = null;
    try {
      debugPrint('[HomeDashboardController] calling repository.findAll()...');
      final result = await repository.findAll().timeout(
        const Duration(seconds: 5),
        onTimeout: () => const Failure(
          ValidationError(
            code: 'timeout',
            message:
                'Tempo limite excedido ao carregar ordens de serviço (timeout de 5s)',
          ),
        ),
      );
      debugPrint('[HomeDashboardController] repository.findAll() finished: $result');
      if (_isDisposed) return;
      switch (result) {
        case Success(:final value):
          data.value = compute(value, DateTime.now());
        case Failure(value: final failure):
          error.value = failure.message;
      }
    } on TimeoutException catch (e) {
      debugPrint('[HomeDashboardController] TimeoutException: $e');
      if (_isDisposed) return;
      error.value = 'Tempo limite excedido ao carregar dados';
    } catch (e, stack) {
      debugPrint('[HomeDashboardController] catch exception: $e\n$stack');
      if (_isDisposed) return;
      error.value = 'Falha ao carregar dados: $e';
    } finally {
      if (!_isDisposed) {
        loading.value = false;
        debugPrint('[HomeDashboardController] loading set to false');
      }
    }
  }

  /// Calcula KPIs e agenda a partir da lista de OS. Visível para teste.
  static HomeDashboardData compute(List<WorkOrder> items, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    var scheduledToday = 0;
    var inProgress = 0;
    var paused = 0;
    var completedToday = 0;
    final upcoming = <WorkOrder>[];

    for (final wo in items) {
      final local = wo.scheduledAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final isToday = !day.isBefore(today) && day.isBefore(tomorrow);

      switch (wo.status) {
        case WorkOrderStatus.scheduled:
          if (isToday) scheduledToday++;
        case WorkOrderStatus.inProgress:
          inProgress++;
        case WorkOrderStatus.paused:
          paused++;
        case WorkOrderStatus.completed:
          if (isToday) completedToday++;
        case WorkOrderStatus.cancelled:
          break;
      }

      final isActionable =
          wo.status == WorkOrderStatus.inProgress ||
          wo.status == WorkOrderStatus.paused;
      final isScheduledAhead =
          wo.status == WorkOrderStatus.scheduled && !local.isBefore(today);
      if (isActionable || isScheduledAhead) upcoming.add(wo);
    }

    upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return HomeDashboardData(
      scheduledToday: scheduledToday,
      inProgress: inProgress,
      paused: paused,
      completedToday: completedToday,
      upcoming: upcoming.take(5).toList(growable: false),
    );
  }

  @override
  void onDispose() {
    _isDisposed = true;
    loading.dispose();
    error.dispose();
    data.dispose();
  }
}
