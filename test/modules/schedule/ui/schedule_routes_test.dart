import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/modules/schedule/ui/schedule_page.dart';
import 'package:service_track/modules/schedule/ui/schedule_routes.dart';
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
  group('ScheduleRoutes', () {
    late ScheduleRoutes routes;

    setUp(() {
      routes = ScheduleRoutes(repository: _FakeWorkOrderRepository());
    });

    testWidgets('schedule() retorna Route que monta SchedulePage', (tester) async {
      final route = routes.schedule();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => Navigator.of(context).push(route),
                child: const Text('Open Schedule'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Schedule'));
      await tester.pumpAndSettle();

      expect(find.byType(SchedulePage), findsOneWidget);
      expect(find.text('Agenda'), findsOneWidget);
    });
  });
}
