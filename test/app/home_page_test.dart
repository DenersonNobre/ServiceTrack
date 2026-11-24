import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/models/money.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/app/home_dashboard_controller.dart';
import 'package:service_track/app/home_page.dart';
import 'package:service_track/modules/work_orders/domain/ports/work_order_repository_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order_status.dart';

class _FakeWorkOrderRepository implements IWorkOrderRepositoryPort {
  _FakeWorkOrderRepository({List<WorkOrder>? initialData, this.failWith})
      : _data = initialData ?? [];

  final List<WorkOrder> _data;
  final String? failWith;
  Completer<IResult<List<WorkOrder>, ValidationError>>? completer;

  @override
  Future<IResult<List<WorkOrder>, ValidationError>> findAll() {
    if (completer != null) return completer!.future;
    if (failWith != null) {
      return Future.value(
        Failure<List<WorkOrder>, ValidationError>(
          ValidationError(code: 'ERR_TEST', message: failWith!),
        ),
      );
    }
    return Future.value(Success<List<WorkOrder>, ValidationError>(_data));
  }

  @override
  Future<IResult<WorkOrder, ValidationError>> save(WorkOrder workOrder) {
    throw UnimplementedError();
  }
}

WorkOrder _makeWorkOrder({
  required String id,
  required String description,
  required WorkOrderStatus status,
  required DateTime scheduledAt,
}) {
  return WorkOrder.restore(
    id: id,
    customerId: 'c1',
    serviceDescription: description,
    scheduledAt: scheduledAt.toUtc(),
    estimatedValue: Money.fromMinorUnits(15000, currencyCode: 'BRL', scale: 2),
    status: status,
  );
}

void main() {
  group('HomePage widget tests', () {
    late HomeDashboardController controller;
    bool profileTapped = false;
    bool customersTapped = false;
    bool workOrdersTapped = false;
    bool newWorkOrderTapped = false;
    bool checklistsTapped = false;
    bool settingsTapped = false;

    Widget buildTestHarness(HomeDashboardController ctrl) {
      return MaterialApp(
        home: HomePage(
          controller: ctrl,
          onProfile: () => profileTapped = true,
          onCustomers: () => customersTapped = true,
          onWorkOrders: () => workOrdersTapped = true,
          onNewWorkOrder: () => newWorkOrderTapped = true,
          onChecklists: () => checklistsTapped = true,
          onSettings: () => settingsTapped = true,
        ),
      );
    }

    setUp(() {
      profileTapped = false;
      customersTapped = false;
      workOrdersTapped = false;
      newWorkOrderTapped = false;
      checklistsTapped = false;
      settingsTapped = false;
    });

    testWidgets('exibe CircularProgressIndicator enquanto loading for true', (
      tester,
    ) async {
      final repo = _FakeWorkOrderRepository();
      repo.completer = Completer<IResult<List<WorkOrder>, ValidationError>>();
      controller = HomeDashboardController(repository: repo);

      await tester.pumpWidget(buildTestHarness(controller));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repo.completer!.complete(
        const Success<List<WorkOrder>, ValidationError>([]),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('exibe mensagem de erro e botão Tentar novamente se repository falhar', (
      tester,
    ) async {
      final repo = _FakeWorkOrderRepository(failWith: 'Erro ao carregar banco');
      controller = HomeDashboardController(repository: repo);

      await tester.pumpWidget(buildTestHarness(controller));
      await tester.pumpAndSettle();

      expect(find.text('Erro ao carregar banco'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      expect(find.text('Erro ao carregar banco'), findsOneWidget);
    });

    testWidgets('renderiza painel com dados vazios (empty state)', (tester) async {
      final repo = _FakeWorkOrderRepository(initialData: []);
      controller = HomeDashboardController(repository: repo);

      await tester.pumpWidget(buildTestHarness(controller));
      await tester.pumpAndSettle();

      expect(find.text('Painel do dia'), findsOneWidget);
      expect(find.text('Nenhuma visita agendada'), findsOneWidget);
      expect(find.text('Crie uma nova OS para aparecer aqui.'), findsOneWidget);
      expect(find.byKey(const Key('home-new-work-order')), findsOneWidget);
    });

    testWidgets('renderiza KPIs e cards de próximas visitas com dados', (
      tester,
    ) async {
      final now = DateTime.now();
      final repo = _FakeWorkOrderRepository(
        initialData: [
          _makeWorkOrder(
            id: 'wo-1',
            description: 'Instalação de Ar Condicionado',
            status: WorkOrderStatus.scheduled,
            scheduledAt: now,
          ),
          _makeWorkOrder(
            id: 'wo-2',
            description: 'Manutenção Preventiva Elevador',
            status: WorkOrderStatus.inProgress,
            scheduledAt: now,
          ),
        ],
      );
      controller = HomeDashboardController(repository: repo);

      await tester.pumpWidget(buildTestHarness(controller));
      await tester.pumpAndSettle();

      expect(find.text('Painel do dia'), findsOneWidget);
      expect(find.text('Instalação de Ar Condicionado'), findsOneWidget);
      expect(find.text('Manutenção Preventiva Elevador'), findsOneWidget);

      // Clicar em Nova OS aciona callback
      await tester.tap(find.byKey(const Key('home-new-work-order')));
      expect(newWorkOrderTapped, isTrue);

      // Clicar em Ver todas aciona callback onWorkOrders
      await tester.tap(find.byKey(const Key('home-see-all-work-orders')));
      expect(workOrdersTapped, isTrue);
    });

    testWidgets('abre o drawer e navega para clientes, ordens, checklists, perfil e configs', (
      tester,
    ) async {
      final repo = _FakeWorkOrderRepository(initialData: []);
      controller = HomeDashboardController(repository: repo);

      await tester.pumpWidget(buildTestHarness(controller));
      await tester.pumpAndSettle();

      // Abrir o Drawer
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('ServiceTrack'), findsWidgets);
      expect(find.text('Gestão de visitas técnicas'), findsOneWidget);

      // Tap Clientes
      await tester.tap(find.byKey(const Key('drawer-customers')));
      await tester.pumpAndSettle();
      expect(customersTapped, isTrue);

      // Reabrir Drawer
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap Ordens de Serviço
      await tester.tap(find.byKey(const Key('drawer-work-orders')));
      await tester.pumpAndSettle();
      expect(workOrdersTapped, isTrue);

      // Reabrir Drawer
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap Modelos de Checklist
      await tester.tap(find.byKey(const Key('drawer-checklists')));
      await tester.pumpAndSettle();
      expect(checklistsTapped, isTrue);

      // Reabrir Drawer
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap Perfil comercial
      await tester.tap(find.byKey(const Key('drawer-profile')));
      await tester.pumpAndSettle();
      expect(profileTapped, isTrue);

      // Reabrir Drawer
      state.openDrawer();
      await tester.pumpAndSettle();

      // Tap Configurações
      await tester.tap(find.byKey(const Key('drawer-settings')));
      await tester.pumpAndSettle();
      expect(settingsTapped, isTrue);
    });

    testWidgets('tocar em cards de KPI chama onWorkOrders', (tester) async {
      final repo = _FakeWorkOrderRepository(initialData: []);
      controller = HomeDashboardController(repository: repo);

      await tester.pumpWidget(buildTestHarness(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home-kpi-scheduled-today-tap')));
      expect(workOrdersTapped, isTrue);
    });
  });
}
