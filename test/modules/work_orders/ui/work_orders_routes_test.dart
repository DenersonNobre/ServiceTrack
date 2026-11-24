import 'dart:async';

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/checklists/data/memory_checklist_answer_repository.dart';
import 'package:service_track/modules/checklists/data/memory_checklist_template_repository.dart';
import 'package:service_track/modules/customers/data/memory_customer_repository.dart';
import 'package:service_track/modules/settings/.index.dart';
import 'package:service_track/modules/work_orders/data/memory_work_order_repository.dart';
import 'package:service_track/modules/work_orders/domain/ports/checklist_proof_port.dart';
import 'package:service_track/modules/work_orders/domain/ports/location_service_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/checklist_completion_proof.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';
import 'package:service_track/modules/work_orders/ui/list/work_order_list_page.dart';
import 'package:service_track/modules/work_orders/ui/work_orders_routes.dart';

final class _FakeLocationService implements ILocationServicePort {
  @override
  Future<IResult<GeoPoint, ValidationError>> getCurrentLocation() async =>
      const Failure(ValidationError(code: 'ERR_FAKE', message: 'fake'));
}

final class _FakeChecklistProofPort implements IChecklistProofPort {
  @override
  Future<IResult<ChecklistCompletionProof, ValidationError>> getProof({
    required String workOrderId,
    required String? templateId,
    bool requireTemplate = true,
  }) async => const Failure(ValidationError(code: 'ERR_FAKE', message: 'fake'));
}

void main() {
  testWidgets(
    'OPS-APP-SHELL-ROUTES - rota de ordens de serviço monta escopo Kortex',
    (tester) async {
      final routes = WorkOrdersRoutes(
        workOrderRepository: MemoryWorkOrderRepository(),
        customerRepository: MemoryCustomerRepository(),
        locationService: _FakeLocationService(),
        checklistProofPort: _FakeChecklistProofPort(),
        checklistTemplateRepository: MemoryChecklistTemplateRepository(),
        checklistAnswerRepository: MemoryChecklistAnswerRepository(),
        settingsRepository: MemorySettingsRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open-work-orders'),
                  onPressed: () {
                    unawaited(Navigator.of(context).push(routes.list()));
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-work-orders')));
      await tester.pumpAndSettle();

      expect(find.text('Ordens de Serviço'), findsOneWidget);
    },
  );

  testWidgets(
    'WorkOrdersRoutes.list repassa onReport para WorkOrderListPage',
    (tester) async {
      String? reportedId;
      final routes = WorkOrdersRoutes(
        workOrderRepository: MemoryWorkOrderRepository(),
        customerRepository: MemoryCustomerRepository(),
        locationService: _FakeLocationService(),
        checklistProofPort: _FakeChecklistProofPort(),
        checklistTemplateRepository: MemoryChecklistTemplateRepository(),
        checklistAnswerRepository: MemoryChecklistAnswerRepository(),
        settingsRepository: MemorySettingsRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open-work-orders-with-report'),
                  onPressed: () {
                    unawaited(
                      Navigator.of(context).push(
                        routes.list(
                          onReport: (id) => reportedId = id,
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir com Report'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-work-orders-with-report')));
      await tester.pumpAndSettle();

      final listPage = tester.widget<WorkOrderListPage>(find.byType(WorkOrderListPage));
      expect(listPage.onReport, isNotNull);
      listPage.onReport!('test-wo-id');
      expect(reportedId, 'test-wo-id');
    },
  );
}
