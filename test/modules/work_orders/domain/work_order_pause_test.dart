import 'dart:typed_data';
// Testes de pausa/retomada de OS (UC-03.04).
//
// SRP: validar transições de pausa/retomada e justificativa obrigatória.


import 'package:dnolib/core/models/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/checklist_completion_proof.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/digital_signature.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/location_capture.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order_status.dart';

void main() {
  WorkOrder scheduled() => WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(1000, currencyCode: 'BRL', scale: 2),
      ).getOrNull()!;

  GeoPoint point() => GeoPoint.tryCreate(
        latitude: -23.5,
        longitude: -46.6,
        timestampUtc: DateTime.utc(2026, 11, 21, 12),
      ).getOrNull()!;

  WorkOrder inProgress() =>
      scheduled().startService(LocationCaptured(point())).getOrNull()!;

  DigitalSignature signature() => DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13]),
        signerName: 'Carlos Silva',
      ).getOrNull()!;

  ChecklistCompletionProof proofOk() =>
      ChecklistCompletionProof.tryCreate(mandatoryTotal: 0, answeredMandatory: 0).getOrNull()!;

  group('WorkOrder.pause/resume (UC-03.04)', () {
    test('IN_PROGRESS -> PAUSED com justificativa', () {
      final r = inProgress().pause('Aguardando peça');
      expect(r.isSuccess, isTrue);
      final wo = r.getOrNull()!;
      expect(wo.status, WorkOrderStatus.paused);
      expect(wo.pauseReason, 'Aguardando peça');
    });

    test('pause rejeita justificativa vazia', () {
      final r = inProgress().pause('   ');
      expect(r.isFailure, isTrue);
      expect(r.getOrNullFailure()!.code, 'ERR_OS_JUSTIFICATIVA_OBRIGATORIA');
    });

    test('SCHEDULED não pode pausar (INV-01)', () {
      final r = scheduled().pause('Motivo');
      expect(r.isFailure, isTrue);
      expect(r.getOrNullFailure()!.code, 'ERR_OS_TRANSICAO_INVALIDA');
    });

    test('PAUSED -> IN_PROGRESS por resume sem GPS', () {
      final paused = inProgress().pause('Aguardando peça').getOrNull()!;
      final r = paused.resume();
      expect(r.isSuccess, isTrue);
      expect(r.getOrNull()!.status, WorkOrderStatus.inProgress);
    });

    test('PAUSED -> CANCELLED com justificativa', () {
      final paused = inProgress().pause('Aguardando peça').getOrNull()!;
      final r = paused.cancel('Cliente desistiu');
      expect(r.isSuccess, isTrue);
      expect(r.getOrNull()!.status, WorkOrderStatus.cancelled);
    });

    test('PAUSED não pode concluir direto (INV-01)', () {
      final paused = inProgress().pause('Aguardando peça').getOrNull()!;
      final r = paused.complete(signature: signature(), checkOut: point(), checklistProof: proofOk());
      expect(r.isFailure, isTrue);
      expect(r.getOrNullFailure()!.code, 'ERR_OS_TRANSICAO_INVALIDA');
    });
  });
}
