// Repositório em memória de OS (testes/fallback).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../domain/ports/work_order_repository_port.dart';
import '../domain/value_objects/work_order.dart';

final class MemoryWorkOrderRepository implements IWorkOrderRepositoryPort {
  final Map<String, WorkOrder> _store = {};

  @override
  Future<IResult<WorkOrder, ValidationError>> save(WorkOrder workOrder) async {
    _store[workOrder.id] = workOrder;
    return Success(workOrder);
  }

  @override
  Future<IResult<List<WorkOrder>, ValidationError>> findAll() async {
    final list = _store.values.toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return Success(list);
  }
}
