// Testes de conclusão e imutabilidade de OS (UC-03.05, INV-01/INV-03/INV-06).
//
// SRP: validar complete/check-out/assinatura e travamento pós-conclusão.

import 'dart:convert';

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

  WorkOrder inProgress() => scheduled()
      .startService(LocationCaptured(point()))
      .getOrNull()!;

  DigitalSignature signature() => DigitalSignature.tryCreate(
        signerName: 'Carlos Silva',
        imageBase64: base64Encode(List<int>.filled(64, 1)),
      ).getOrNull()!;

  ChecklistCompletionProof proofOk() =>
      ChecklistCompletionProof.tryCreate(mandatoryTotal: 0, answeredMandatory: 0).getOrNull()!;

  group('WorkOrder.complete (UC-03.05)', () {
    test('IN_PROGRESS + assinatura + checklist completo + check-out -> COMPLETED', () {
      final r = inProgress().complete(
        signature: signature(),
        checkOut: point(),
        checklistProof: proofOk(),
      );
      expect(r.isSuccess, isTrue);
      final wo = r.getOrNull()!;
      expect(wo.status, WorkOrderStatus.completed);
      expect(wo.checkOut, isNotNull);
      expect(wo.signature, isNotNull);
    });

    test('falha quando checklist obrigatório pendente (INV-SEC-22)', () {
      final badProof = ChecklistCompletionProof.tryCreate(mandatoryTotal: 2, answeredMandatory: 1);
      expect(badProof.isFailure, isTrue);
    });

    test('falha quando OS não está IN_PROGRESS (INV-01)', () {
      final r = scheduled().complete(
        signature: signature(),
        checkOut: point(),
        checklistProof: proofOk(),
      );
      expect(r.isFailure, isTrue);
      expect(r.getOrNullFailure()!.code, 'ERR_OS_TRANSICAO_INVALIDA');
    });

    test('OS COMPLETED é imutável (INV-06/INV-SEC-23)', () {
      final completed = inProgress().complete(
        signature: signature(),
        checkOut: point(),
        checklistProof: proofOk(),
      ).getOrNull()!;
      final r = completed.cancel('tentativa');
      expect(r.isFailure, isTrue);
      expect(r.getOrNullFailure()!.code, 'ERR_OS_TRANSICAO_INVALIDA');
    });

    test('assinatura/recebedor redigidos em toString (INV-SEC-24)', () {
      final sig = signature();
      expect(sig.toString(), contains('redacted'));
      expect(sig.toString(), isNot(contains('Carlos')));
    });
  });
}
