import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/core/models/money.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/modules/schedule/ui/day/schedule_day_controller.dart';
import 'package:service_track/modules/schedule/ui/day/schedule_day_page.dart';
import 'package:service_track/modules/settings/domain/entities/settings_snapshot.dart';
import 'package:service_track/modules/settings/domain/ports/settings_repository_port.dart';
import 'package:service_track/modules/settings/domain/value_objects/setting_key.dart';
import 'package:service_track/modules/settings/features/get_settings.dart';
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

class _FakeSettingsRepository implements ISettingsRepositoryPort {
  _FakeSettingsRepository({SettingsSnapshot? snapshot})
      : _snapshot = snapshot ?? SettingsSnapshot.defaults();
  final SettingsSnapshot _snapshot;

  @override
  Future<IResult<SettingsSnapshot, ValidationError>> load() async {
    return Success(_snapshot);
  }

  @override
  Future<IResult<SettingsSnapshot, ValidationError>> update(
    SettingKey key,
    Object value,
  ) async {
    return Success(_snapshot);
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
    customerId: 'cust-1',
    serviceDescription: description,
    scheduledAt: scheduledAt,
    estimatedValue: Money.fromMinorUnits(15000, currencyCode: 'BRL', scale: 2),
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
  group('ScheduleDayController', () {
    late _FakeWorkOrderRepository woRepo;
    late _FakeSettingsRepository settingsRepo;
    late ScheduleDayController controller;

    setUp(() {
      final wo1 = _makeWorkOrder(
        id: 'wo-1',
        description: 'Troca de Disjuntor',
        scheduledAt: DateTime(2026, 11, 25, 9, 0),
      );
      final wo2 = _makeWorkOrder(
        id: 'wo-2',
        description: 'Instalação de Tomadas',
        scheduledAt: DateTime(2026, 11, 26, 10, 0),
      );
      woRepo = _FakeWorkOrderRepository(data: [wo1, wo2]);
      settingsRepo = _FakeSettingsRepository(
        snapshot: SettingsSnapshot({
          SettingKey.scheduleDayStart: '08:00',
          SettingKey.scheduleDayEnd: '18:00',
          SettingKey.scheduleSlotInterval: 30,
        }),
      );
      controller = ScheduleDayController(
        repository: woRepo,
        getSettings: GetSettings(repository: settingsRepo),
        initialDate: DateTime(2026, 11, 25),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state and generated slots based on settings', () async {
      await controller.load();
      expect(controller.selectedDate.value.year, 2026);
      expect(controller.selectedDate.value.month, 11);
      expect(controller.selectedDate.value.day, 25);

      expect(controller.timeSlots.value, isNotEmpty);
      expect(controller.timeSlots.value.first, '08:00');
      expect(controller.timeSlots.value.last, '18:00');

      // 08:00 a 18:00 em passos de 30 min = 21 slots
      expect(controller.timeSlots.value.length, 21);

      // Deve filtrar apenas as OS do dia 25
      expect(controller.dayWorkOrders.value.length, 1);
      expect(controller.dayWorkOrders.value.first.id, 'wo-1');
    });

    test('nextDay and previousDay updates selectedDate and reloads', () async {
      await controller.load();
      controller.nextDay();
      expect(controller.selectedDate.value.day, 26);
      expect(controller.dayWorkOrders.value.length, 1);
      expect(controller.dayWorkOrders.value.first.id, 'wo-2');

      controller.previousDay();
      expect(controller.selectedDate.value.day, 25);
      expect(controller.dayWorkOrders.value.first.id, 'wo-1');
    });
  });

  group('ScheduleDayPage', () {
    late _FakeWorkOrderRepository woRepo;
    late _FakeSettingsRepository settingsRepo;
    late ScheduleDayController controller;

    setUp(() async {
      final wo1 = _makeWorkOrder(
        id: 'wo-1',
        description: 'Manutenção Preventiva',
        scheduledAt: DateTime(2026, 11, 25, 9, 30),
      );
      woRepo = _FakeWorkOrderRepository(data: [wo1]);
      settingsRepo = _FakeSettingsRepository();
      controller = ScheduleDayController(
        repository: woRepo,
        getSettings: GetSettings(repository: settingsRepo),
        initialDate: DateTime(2026, 11, 25),
      );
      await controller.load();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders top date header, previous/next buttons and vertical timeline slots', (tester) async {
      String? tappedWoId;
      DateTime? tappedSlotDate;
      String? tappedSlotTime;

      await tester.pumpWidget(
        MaterialApp(
          home: KortexScope(
            providers: [KortexProvider<ScheduleDayController>.value(value: controller)],
            child: ScheduleDayPage(
              onWorkOrderTapped: (id) => tappedWoId = id,
              onEmptySlotTapped: (date, time) {
                tappedSlotDate = date;
                tappedSlotTime = time;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar header: data e navegação
      expect(find.byKey(const Key('schedule-day-prev')), findsOneWidget);
      expect(find.byKey(const Key('schedule-day-next')), findsOneWidget);
      expect(find.textContaining('25'), findsWidgets);

      // Timeline vertical slots
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('09:30'), findsOneWidget);

      // Scroll para encontrar '18:00' no final da lista
      await tester.scrollUntilVisible(find.text('18:00'), 500);
      expect(find.text('18:00'), findsOneWidget);

      // Compromisso agendado para 09:30
      await tester.scrollUntilVisible(find.text('Manutenção Preventiva'), -500);
      expect(find.text('Manutenção Preventiva'), findsOneWidget);

      // Ao tocar no compromisso, aciona callback
      await tester.tap(find.text('Manutenção Preventiva'));
      expect(tappedWoId, 'wo-1');

      // Ao tocar em um slot livre (ex: 08:00)
      await tester.scrollUntilVisible(find.byKey(const Key('schedule-slot-08:00')), -500);
      await tester.tap(find.byKey(const Key('schedule-slot-08:00')));
      expect(tappedSlotDate?.day, 25);
      expect(tappedSlotTime, '08:00');
    });
  });
}
