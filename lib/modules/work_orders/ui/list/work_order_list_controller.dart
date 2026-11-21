// Controller da lista de OS (UC-03.01 base).
//
// SRP: carregar e expor OS. Não renderiza UI.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../domain/ports/work_order_repository_port.dart';
import '../../domain/value_objects/work_order.dart';

final class WorkOrderListController extends IKortexController {
  WorkOrderListController({required this.repository});
  final IWorkOrderRepositoryPort repository;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<List<WorkOrder>> items = KortexSignal<List<WorkOrder>>([]);
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  bool _loaded = false;

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
  }
}
