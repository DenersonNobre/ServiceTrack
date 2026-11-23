import 'package:dnolib/core/models/money.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/settings/.index.dart';
import 'package:service_track/modules/work_orders/data/memory_work_order_repository.dart';
import 'package:service_track/modules/work_orders/domain/ports/checklist_proof_port.dart';
import 'package:service_track/modules/work_orders/domain/ports/location_service_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/checklist_completion_proof.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/location_capture.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/ui/list/work_order_list_controller.dart';
import 'package:service_track/modules/work_orders/ui/list/work_order_list_page.dart';

final class _LocationOk implements ILocationServicePort {
  @override
  Future<IResult<GeoPoint, ValidationError>> getCurrentLocation() async =>
      GeoPoint.tryCreate(
        latitude: -23.5,
        longitude: -46.6,
        timestampUtc: DateTime.utc(2026, 11, 21, 12),
      );
}

final class _ProofOk implements IChecklistProofPort {
  @override
  Future<IResult<ChecklistCompletionProof, ValidationError>> getProof({
    required String workOrderId,
    required String? templateId,
    bool requireTemplate = true,
  }) async => ChecklistCompletionProof.tryCreate(
    mandatoryTotal: 1,
    answeredMandatory: 1,
  );
}

Future<MemoryWorkOrderRepository> _repoWithInProgress() async {
  final repo = MemoryWorkOrderRepository();
  final base = WorkOrder.tryCreate(
    id: 'wo1',
    customerId: 'c1',
    serviceDescription: 'Instalação',
    scheduledAt: DateTime.utc(2026, 11, 22, 14),
    estimatedValue: Money.fromMinorUnits(1000, currencyCode: 'BRL', scale: 2),
  ).getOrNull()!;
  final started = base
      .startService(
        LocationCaptured(
          GeoPoint.tryCreate(
            latitude: -23.5,
            longitude: -46.6,
            timestampUtc: DateTime.utc(2026, 11, 21, 12),
          ).getOrNull()!,
        ),
      )
      .getOrNull()!;
  await repo.save(started);
  return repo;
}

void main() {
  testWidgets(
    'UC-07.03/SEC-04 - documento não é coletado quando proteção está indisponível',
    (tester) async {
      final repo = await _repoWithInProgress();
      final settings = MemorySettingsRepository(
        SettingsSnapshot({SettingKey.requireReceiverDocument: true}),
      );
      final controller = WorkOrderListController(
        repository: repo,
        locationService: _LocationOk(),
        checklistProofPort: _ProofOk(),
        getSettings: GetSettings(repository: settings),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KortexScope(
            providers: [
              KortexProvider<WorkOrderListController>(
                create: (_) => controller,
                dispose: (c) => c.dispose(),
              ),
            ],
            child: const WorkOrderListPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('wo-actions-wo1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir OS'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('wo-complete-doc')), findsNothing);
      expect(find.textContaining('proteção em repouso'), findsOneWidget);
    },
  );
}
