import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/models/money.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/modules/schedule/ui/schedule_controller.dart';
import 'package:service_track/modules/work_orders/domain/ports/work_order_repository_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order_status.dart';

class _FakeWorkOrderRepository implements IWorkOrderRepositoryPort {
  _FakeWorkOrderRepository({List<WorkOrder>? data, this.failWith})
      : _data = data ?? [];

  final List<WorkOrder> _data;
  final String? failWith;

  @override
  Future<IResult<List<WorkOrder>, ValidationError>> findAll() async {
    if (failWith != null) {
      return Failure(ValidationError(code: 'ERR_TEST', message: failWith!));
    }
    return Success(_data);
  }

  @override
  Future<IResult<WorkOrder, ValidationError>> save(WorkOrder workOrder) {
    throw UnimplementedError();
  }
}

WorkOrder _makeWorkOrder({
  required String id,
  required String description,
  required DateTime scheduledAt,
  WorkOrderStatus status = WorkOrderStatus.scheduled,
}) {
  return WorkOrder.restore(
    id: id,
    customerId: 'c1',
    serviceDescription: description,
    scheduledAt: scheduledAt,
    estimatedValue: Money.fromMinorUnits(10000, currencyCode: 'BRL', scale: 2),
    status: status,
    checkIn: null,
    cancellationReason: null,
    pauseReason: null,
    checkOut: null,
    signature: null,
    checklistProof: null,
    checklistTemplateId: null,
  );
}

void main() {
  group('ScheduleController', () {
    late _FakeWorkOrderRepository repo;
    late ScheduleController controller;

    setUp(() {
      repo = _FakeWorkOrderRepository();
      controller = ScheduleController(
        repository: repo,
        initialDate: DateTime(2026, 11, 15, 10, 0),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state sets currentMonth and selectedDate based on initialDate', () {
      expect(controller.currentMonth.value.year, 2026);
      expect(controller.currentMonth.value.month, 11);
      expect(controller.currentMonth.value.day, 1);
      expect(controller.selectedDate.value, DateTime(2026, 11, 15, 10, 0));
      expect(controller.workOrders.value, isEmpty);
      expect(controller.loading.value, isFalse);
      expect(controller.error.value, isNull);
    });

    test('nextMonth advances month by 1', () {
      controller.nextMonth();
      expect(controller.currentMonth.value.year, 2026);
      expect(controller.currentMonth.value.month, 12);

      controller.nextMonth();
      expect(controller.currentMonth.value.year, 2027);
      expect(controller.currentMonth.value.month, 1);
    });

    test('previousMonth decrements month by 1', () {
      controller.previousMonth();
      expect(controller.currentMonth.value.year, 2026);
      expect(controller.currentMonth.value.month, 10);

      // Volta até virar o ano
      for (var i = 0; i < 10; i++) {
        controller.previousMonth();
      }
      expect(controller.currentMonth.value.year, 2025);
      expect(controller.currentMonth.value.month, 12);
    });

    test('nextYear advances year by 1 keeping the month', () {
      controller.nextYear();
      expect(controller.currentMonth.value.year, 2027);
      expect(controller.currentMonth.value.month, 11);
    });

    test('previousYear decrements year by 1 keeping the month', () {
      controller.previousYear();
      expect(controller.currentMonth.value.year, 2025);
      expect(controller.currentMonth.value.month, 11);
    });

    test('selectDate updates selectedDate', () {
      final newDate = DateTime(2026, 11, 20);
      controller.selectDate(newDate);
      expect(controller.selectedDate.value, newDate);
    });

    test('jumpToToday resets month and selected date to today', () {
      controller.nextMonth();
      controller.nextYear();
      controller.jumpToToday();

      final now = DateTime.now();
      expect(controller.currentMonth.value.year, now.year);
      expect(controller.currentMonth.value.month, now.month);
      expect(controller.selectedDate.value?.day, now.day);
      expect(controller.selectedDate.value?.month, now.month);
      expect(controller.selectedDate.value?.year, now.year);
    });

    test('load populates workOrders and filters correctly for date', () async {
      final wo1 = _makeWorkOrder(
        id: 'wo-1',
        description: 'Manutenção Preventiva',
        scheduledAt: DateTime(2026, 11, 15, 9, 30),
      );
      final wo2 = _makeWorkOrder(
        id: 'wo-2',
        description: 'Instalação de Ar',
        scheduledAt: DateTime(2026, 11, 15, 14, 0),
      );
      final wo3 = _makeWorkOrder(
        id: 'wo-3',
        description: 'Troca de Peça',
        scheduledAt: DateTime(2026, 11, 16, 10, 0),
      );

      final populatedRepo = _FakeWorkOrderRepository(data: [wo1, wo2, wo3]);
      final ctrl = ScheduleController(
        repository: populatedRepo,
        initialDate: DateTime(2026, 11, 15),
      );

      await ctrl.load();

      expect(ctrl.workOrders.value.length, 3);
      expect(ctrl.workOrdersForDate(DateTime(2026, 11, 15)).length, 2);
      expect(ctrl.countForDate(DateTime(2026, 11, 15)), 2);
      expect(ctrl.selectedDateWorkOrders.length, 2);

      expect(ctrl.workOrdersForDate(DateTime(2026, 11, 16)).length, 1);
      expect(ctrl.countForDate(DateTime(2026, 11, 16)), 1);

      expect(ctrl.workOrdersForDate(DateTime(2026, 11, 17)), isEmpty);
      expect(ctrl.countForDate(DateTime(2026, 11, 17)), 0);

      ctrl.dispose();
    });

    test('load handles repository error gracefully', () async {
      final errorRepo = _FakeWorkOrderRepository(failWith: 'Erro ao buscar OSs');
      final ctrl = ScheduleController(
        repository: errorRepo,
        initialDate: DateTime(2026, 11, 15),
      );

      await ctrl.load();

      expect(ctrl.loading.value, isFalse);
      expect(ctrl.error.value, 'Erro ao buscar OSs');
      expect(ctrl.workOrders.value, isEmpty);

      ctrl.dispose();
    });
  });
}
