import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/core/models/money.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/modules/settings/.index.dart';
import 'package:service_track/modules/work_orders/data/memory_work_order_repository.dart';
import 'package:service_track/modules/work_orders/domain/ports/checklist_proof_port.dart';
import 'package:service_track/modules/work_orders/domain/ports/location_service_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/checklist_completion_proof.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/digital_signature.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/location_capture.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/ui/list/work_order_list_controller.dart';
import 'package:service_track/modules/work_orders/ui/list/work_order_list_page.dart';

final class _DummyLocation implements ILocationServicePort {
  @override
  Future<IResult<GeoPoint, ValidationError>> getCurrentLocation() async =>
      GeoPoint.tryCreate(
        latitude: -23.5,
        longitude: -46.6,
        timestampUtc: DateTime.utc(2026, 11, 21, 12),
      );
}

final class _DummyProof implements IChecklistProofPort {
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

void main() {
  group('UC-05.04 - WorkOrderListPage - Visualizar Laudo', () {
    testWidgets(
      'Para OS com status COMPLETED, exibe menu de ações com opção "Visualizar Laudo" e dispara onReport',
      (tester) async {
        final repo = MemoryWorkOrderRepository();
        final base = WorkOrder.tryCreate(
          id: 'wo-completed-1',
          customerId: 'c1',
          serviceDescription: 'Manutenção Preventiva Concluída',
          scheduledAt: DateTime.utc(2026, 11, 22, 14),
          estimatedValue: Money.fromMinorUnits(15000, currencyCode: 'BRL', scale: 2),
        ).getOrNull()!;

        final geo = GeoPoint.tryCreate(
          latitude: -23.5,
          longitude: -46.6,
          timestampUtc: DateTime.utc(2026, 11, 21, 12),
        ).getOrNull()!;

        final started = base.startService(LocationCaptured(geo)).getOrNull()!;

        final sig = DigitalSignature.tryCreate(
          signatureBytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13]),
          signerName: 'João da Silva',
        ).getOrNull()!;

        final completed = started.complete(
          checkOut: geo,
          signature: sig,
          checklistProof: ChecklistCompletionProof.tryCreate(
            mandatoryTotal: 1,
            answeredMandatory: 1,
          ).getOrNull()!,
        ).getOrNull()!;

        await repo.save(completed);

        final controller = WorkOrderListController(
          repository: repo,
          locationService: _DummyLocation(),
          checklistProofPort: _DummyProof(),
          getSettings: GetSettings(repository: MemorySettingsRepository()),
        );

        String? reportedWorkOrderId;

        await tester.pumpWidget(
          MaterialApp(
            home: KortexScope(
              providers: [
                KortexProvider<WorkOrderListController>(
                  create: (_) => controller,
                  dispose: (c) => c.dispose(),
                ),
              ],
              child: WorkOrderListPage(
                onReport: (woId) {
                  reportedWorkOrderId = woId;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifica se a OS concluída aparece
        expect(find.text('Manutenção Preventiva Concluída'), findsOneWidget);

        // Abre o menu de ações da OS concluída
        final actionButton = find.byKey(const Key('wo-actions-wo-completed-1'));
        expect(actionButton, findsOneWidget);

        await tester.tap(actionButton);
        await tester.pumpAndSettle();

        // Verifica se o item "Visualizar Laudo" está presente
        final reportMenuItem = find.byKey(const Key('wo-action-report-wo-completed-1'));
        expect(reportMenuItem, findsOneWidget);
        expect(find.text('Visualizar Laudo'), findsOneWidget);

        // Toca no item "Visualizar Laudo"
        await tester.tap(reportMenuItem);
        await tester.pumpAndSettle();

        // Valida que o callback onReport foi acionado com o id correto
        expect(reportedWorkOrderId, 'wo-completed-1');
      },
    );
  });
}
