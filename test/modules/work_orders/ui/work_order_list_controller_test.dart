import 'package:dnolib/core/models/money.dart';
import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/work_orders/data/memory_work_order_repository.dart';
import 'package:service_track/modules/work_orders/domain/ports/location_service_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order_status.dart';
import 'package:service_track/modules/work_orders/ui/list/work_order_list_controller.dart';

class _FakeLocationService implements ILocationServicePort {
  @override
  Future<IResult<GeoPoint, ValidationError>> getCurrentLocation() async {
    return const Failure(ValidationError(code: 'ERR_LOCALIZACAO_INDISPONIVEL', message: 'x'));
  }
}

void main() {
  WorkOrder wo(String id, WorkOrderStatus status, DateTime at) => WorkOrder.restore(
        id: id,
        customerId: 'c1',
        serviceDescription: 'OS $id',
        scheduledAt: at,
        estimatedValue: Money.fromMinorUnits(1000, currencyCode: 'BRL', scale: 2),
        status: status,
      );

  test('UC-03.02 - filtra ordens por chip', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10).toUtc();
    final tomorrow = today.add(const Duration(days: 1));
    final repo = MemoryWorkOrderRepository();
    await repo.save(wo('1', WorkOrderStatus.scheduled, today));
    await repo.save(wo('2', WorkOrderStatus.inProgress, tomorrow));
    await repo.save(wo('3', WorkOrderStatus.completed, today));

    final c = WorkOrderListController(repository: repo, locationService: _FakeLocationService());
    await c.load();

    c.filter.value = WorkOrderListFilter.today;
    expect(c.filteredItems.map((e) => e.id).toSet(), {'1', '3'});

    c.filter.value = WorkOrderListFilter.scheduled;
    expect(c.filteredItems.map((e) => e.id), ['1']);

    c.filter.value = WorkOrderListFilter.inProgress;
    expect(c.filteredItems.map((e) => e.id), ['2']);

    c.filter.value = WorkOrderListFilter.completed;
    expect(c.filteredItems.map((e) => e.id), ['3']);

    c.filter.value = WorkOrderListFilter.all;
    expect(c.filteredItems.length, 3);
    c.dispose();
  });
}
