import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/modules/home/ui/home_page.dart';
import 'package:service_track/modules/home/ui/home_routes.dart';
import 'package:service_track/modules/work_orders/domain/ports/work_order_repository_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';

class _FakeWorkOrderRepository implements IWorkOrderRepositoryPort {
  @override
  Future<IResult<List<WorkOrder>, ValidationError>> findAll() async {
    return const Success<List<WorkOrder>, ValidationError>([]);
  }

  @override
  Future<IResult<WorkOrder, ValidationError>> save(WorkOrder workOrder) {
    throw UnimplementedError();
  }
}

void main() {
  group('HomeRoutes', () {
    late HomeRoutes routes;

    setUp(() {
      routes = HomeRoutes(workOrderRepository: _FakeWorkOrderRepository());
    });

    testWidgets('home() retorna Route que monta HomePage', (tester) async {
      final route = routes.home(
        onProfile: () {},
        onCustomers: () {},
        onWorkOrders: () {},
        onNewWorkOrder: () {},
        onChecklists: () {},
        onSettings: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => Navigator.of(context).push(route),
                child: const Text('Open Home'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Home'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('homeWidget() monta HomePage com KortexScope provido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: routes.homeWidget(
            onProfile: () {},
            onCustomers: () {},
            onWorkOrders: () {},
            onNewWorkOrder: () {},
            onChecklists: () {},
            onSettings: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
