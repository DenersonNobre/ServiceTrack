import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/models/money.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/app/home_dashboard_controller.dart';
import 'package:service_track/modules/work_orders/domain/ports/work_order_repository_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order_status.dart';

class _FakeWorkOrderRepository implements IWorkOrderRepositoryPort {
  Completer<IResult<List<WorkOrder>, ValidationError>>? findAllCompleter;

  @override
  Future<IResult<List<WorkOrder>, ValidationError>> findAll() {
    if (findAllCompleter != null) {
      return findAllCompleter!.future;
    }
    return Future.value(const Success<List<WorkOrder>, ValidationError>([]));
  }

  @override
  Future<IResult<WorkOrder, ValidationError>> save(WorkOrder workOrder) {
    throw UnimplementedError();
  }
}

WorkOrder _wo({
  required String id,
  required WorkOrderStatus status,
  required DateTime scheduledAt,
}) {
  return WorkOrder.restore(
    id: id,
    customerId: 'c1',
    serviceDescription: 'Serviço $id',
    scheduledAt: scheduledAt.toUtc(),
    estimatedValue: Money.fromMinorUnits(1000, currencyCode: 'BRL', scale: 2),
    status: status,
  );
}

void main() {
  group('HomeDashboardController.load async guard & dispose', () {
    test('load() não lança StateError e aborta quando controller é disposed durante findAll()', () async {
      final repo = _FakeWorkOrderRepository();
      repo.findAllCompleter = Completer<IResult<List<WorkOrder>, ValidationError>>();

      final controller = HomeDashboardController(repository: repo);

      // Inicia a carga assíncrona
      final loadFuture = controller.load();

      // Controller é descartado antes do findAll resolver (ex: transição de rota / pop)
      controller.dispose();

      // Agora resolve o repositório com sucesso
      repo.findAllCompleter!.complete(
        const Success<List<WorkOrder>, ValidationError>([]),
      );

      // Não deve lançar StateError (Bad state: KortexSignal used after dispose())
      await expectLater(loadFuture, completes);
    });

    test('load() aborta imediatamente se controller já estiver disposed', () async {
      final repo = _FakeWorkOrderRepository();
      final controller = HomeDashboardController(repository: repo);

      controller.dispose();

      // Chamada a load com controller já disposed não deve tentar mutar loading nem chamar repo
      await expectLater(controller.load(), completes);
    });
  });

  group('HomeDashboardController.compute', () {
    test('calcula KPIs do dia e próximas visitas', () {
      final now = DateTime(2026, 11, 23, 10, 0);
      final today = DateTime(2026, 11, 23, 14, 0);
      final tomorrow = DateTime(2026, 11, 24, 9, 0);
      final yesterday = DateTime(2026, 11, 22, 9, 0);

      final data = HomeDashboardController.compute([
        _wo(id: '1', status: WorkOrderStatus.scheduled, scheduledAt: today),
        _wo(
          id: '2',
          status: WorkOrderStatus.inProgress,
          scheduledAt: yesterday,
        ),
        _wo(
          id: '3',
          status: WorkOrderStatus.paused,
          scheduledAt: DateTime(2026, 11, 22, 10, 0),
        ),
        _wo(id: '4', status: WorkOrderStatus.completed, scheduledAt: today),
        _wo(id: '5', status: WorkOrderStatus.cancelled, scheduledAt: today),
        _wo(id: '6', status: WorkOrderStatus.scheduled, scheduledAt: tomorrow),
      ], now);

      expect(data.scheduledToday, 1);
      expect(data.inProgress, 1);
      expect(data.paused, 1);
      expect(data.completedToday, 1);
      expect(data.upcoming.map((e) => e.id), ['2', '3', '1', '6']);
    });

    test('upcoming ignora concluídas/canceladas e limita a 5', () {
      final now = DateTime(2026, 11, 23, 8, 0);
      final items = List.generate(
        7,
        (i) => _wo(
          id: '$i',
          status: WorkOrderStatus.scheduled,
          scheduledAt: DateTime(2026, 11, 23, 9 + i),
        ),
      );

      final data = HomeDashboardController.compute(items, now);

      expect(data.upcoming, hasLength(5));
      expect(data.upcoming.first.id, '0');
      expect(data.upcoming.last.id, '4');
    });
  });
}
