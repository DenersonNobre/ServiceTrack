// Controller da lista de OS (UC-03.01 base, UC-03.02 filtros).
//
// SRP: carregar e expor OS com filtros de visita. Não renderiza UI.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../domain/ports/work_order_repository_port.dart';
import '../../domain/value_objects/work_order.dart';
import '../../domain/value_objects/work_order_status.dart';

/// Filtros rápidos do painel de visitas (UC-03.02).
enum WorkOrderListFilter { all, today, scheduled, inProgress, completed }

final class WorkOrderListController extends IKortexController {
  WorkOrderListController({required this.repository});
  final IWorkOrderRepositoryPort repository;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<List<WorkOrder>> items = KortexSignal<List<WorkOrder>>([]);
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  final KortexSignal<WorkOrderListFilter> filter =
      KortexSignal<WorkOrderListFilter>(WorkOrderListFilter.all);
  bool _loaded = false;

  /// Itens filtrados pelo chip selecionado.
  List<WorkOrder> get filteredItems {
    final selected = filter.value;
    final all = items.value;
    if (selected == WorkOrderListFilter.all) return all;
    final now = DateTime.now();
    return all.where((wo) {
      return switch (selected) {
        WorkOrderListFilter.all => true,
        WorkOrderListFilter.today => _isSameLocalDay(wo.scheduledAt, now),
        WorkOrderListFilter.scheduled => wo.status == WorkOrderStatus.scheduled,
        WorkOrderListFilter.inProgress => wo.status == WorkOrderStatus.inProgress,
        WorkOrderListFilter.completed => wo.status == WorkOrderStatus.completed,
      };
    }).toList();
  }

  bool _isSameLocalDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final result = await repository.findAll();
    loading.value = false;
    switch (result) {
      case Success<List<WorkOrder>, ValidationError>(:final value):
        items.value = value;
      case Failure<List<WorkOrder>, ValidationError>(:final value):
        error.value = value.message;
    }
  }

  @override
  void onDispose() {
    loading.dispose();
    items.dispose();
    error.dispose();
    filter.dispose();
  }
}
