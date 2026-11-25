import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/core/models/money.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/modules/schedule/ui/schedule_controller.dart';
import 'package:service_track/modules/schedule/ui/schedule_page.dart';
import 'package:service_track/modules/work_orders/domain/ports/work_order_repository_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order_status.dart';

class _FakeWorkOrderRepository implements IWorkOrderRepositoryPort {
  _FakeWorkOrderRepository({List<WorkOrder>? data}) : _data = data ?? [];
  final List<WorkOrder> _data;

  @override
  Future<IResult<List<WorkOrder>, ValidationError>> findAll() async {
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
    estimatedValue: Money.fromMinorUnits(12000, currencyCode: 'BRL', scale: 2),
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

Widget _wrap(ScheduleController controller) {
  return MaterialApp(
    home: KortexScope(
      providers: [KortexProvider<ScheduleController>.value(value: controller)],
      child: const SchedulePage(),
    ),
  );
}

void main() {
  group('SchedulePage', () {
    late _FakeWorkOrderRepository repo;
    late ScheduleController controller;

    setUp(() async {
      final wo1 = _makeWorkOrder(
        id: 'wo-1',
        description: 'Revisão Elétrica',
        scheduledAt: DateTime(2026, 11, 15, 9, 0),
      );
      repo = _FakeWorkOrderRepository(data: [wo1]);
      controller = ScheduleController(
        repository: repo,
        initialDate: DateTime(2026, 11, 15),
      );
      await controller.load();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders calendar header, week days, and day cells', (tester) async {
      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Novembro 2026'), findsOneWidget);
      expect(find.text('Dom'), findsOneWidget);
      expect(find.text('Seg'), findsOneWidget);
      expect(find.text('Sáb'), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);

      // Dia 15 no grid
      expect(find.text('15'), findsWidgets);
      // OS agendada no dia selecionado
      expect(find.text('Revisão Elétrica'), findsOneWidget);
    });

    testWidgets('tap on day cell selects that day and updates appointment list', (tester) async {
      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();

      expect(find.text('Revisão Elétrica'), findsOneWidget);

      // Clica no dia 20 (que não tem OS)
      final day20 = find.widgetWithText(InkWell, '20');
      if (day20.evaluate().isNotEmpty) {
        await tester.tap(day20.first);
      } else {
        await tester.tap(find.text('20').first);
      }
      await tester.pumpAndSettle();

      expect(controller.selectedDate.value?.day, 20);
      expect(find.text('Revisão Elétrica'), findsNothing);
      expect(find.textContaining('Nenhum atendimento'), findsOneWidget);
    });

    testWidgets('horizontal swipe advances and recedes months', (tester) async {
      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Novembro 2026'), findsOneWidget);

      // Swipe para a esquerda (drag left) -> avança para Dezembro
      await tester.drag(find.byKey(const Key('schedule-gesture-detector')), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dezembro 2026'), findsOneWidget);
      expect(controller.currentMonth.value.month, 12);

      // Swipe para a direita (drag right) -> volta para Novembro
      await tester.drag(find.byKey(const Key('schedule-gesture-detector')), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(find.textContaining('Novembro 2026'), findsOneWidget);
      expect(controller.currentMonth.value.month, 11);
    });

    testWidgets('vertical swipe advances and recedes years', (tester) async {
      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();

      expect(find.textContaining('Novembro 2026'), findsOneWidget);

      // Swipe para cima (drag up) -> avança ano (+1)
      await tester.drag(find.byKey(const Key('schedule-gesture-detector')), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.textContaining('Novembro 2027'), findsOneWidget);
      expect(controller.currentMonth.value.year, 2027);

      // Swipe para baixo (drag down) -> recua ano (-1)
      await tester.drag(find.byKey(const Key('schedule-gesture-detector')), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(find.textContaining('Novembro 2026'), findsOneWidget);
      expect(controller.currentMonth.value.year, 2026);
    });

    testWidgets('tap on Hoje button resets month and selection', (tester) async {
      await tester.pumpWidget(_wrap(controller));
      await tester.pumpAndSettle();

      // Navega para outro ano via botão de cabeçalho ou controller
      controller.nextYear();
      await tester.pumpAndSettle();
      expect(find.textContaining('2027'), findsOneWidget);

      await tester.tap(find.text('Hoje'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      expect(controller.currentMonth.value.year, now.year);
      expect(controller.currentMonth.value.month, now.month);
    });
  });
}
