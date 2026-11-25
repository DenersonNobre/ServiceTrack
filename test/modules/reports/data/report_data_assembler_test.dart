import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/models/money.dart';
import 'package:service_track/modules/checklists/domain/entities/checklist_answer.dart';
import 'package:service_track/modules/checklists/domain/entities/checklist_template.dart';
import 'package:service_track/modules/customers/domain/value_objects/customer.dart';
import 'package:service_track/modules/evidences/domain/entities/digital_signature.dart';
import 'package:service_track/modules/profile/domain/value_objects/technician_profile.dart';
import 'package:service_track/modules/reports/data/report_data_assembler.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/check_in_record.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order_status.dart';

void main() {
  group('ReportDataAssembler', () {
    WorkOrder buildCompletedWorkOrder({
      String id = 'wo-1',
      String customerId = 'cust-1',
      DateTime? scheduledAt,
      DateTime? completedAt,
      String? checklistTemplateId = 'tpl-1',
    }) {
      final checkInPoint = GeoPoint.tryCreate(
        latitude: -23.5505,
        longitude: -46.6333,
        timestampUtc: DateTime.utc(2026, 11, 24, 12, 5),
      ).getOrNull()!;
      final checkOutPoint = GeoPoint.tryCreate(
        latitude: -23.5506,
        longitude: -46.6334,
        timestampUtc: completedAt ?? DateTime.utc(2026, 11, 24, 14, 30),
      ).getOrNull()!;
      final signature = DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList(
          const [137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3],
        ),
        signerName: 'João Cliente',
        documentNumber: '12345678900',
        signedAtUtc: DateTime.utc(2026, 11, 24, 14, 31),
      ).getOrNull()!;

      return WorkOrder.restore(
        id: id,
        customerId: customerId,
        serviceDescription: 'Instalação de ar-condicionado',
        scheduledAt: scheduledAt ?? DateTime.utc(2026, 11, 24, 12, 0),
        estimatedValue:
            Money.fromMinorUnits(85000, currencyCode: 'BRL', scale: 2),
        status: WorkOrderStatus.completed,
        checkIn: CheckInGps(checkInPoint),
        checkOut: checkOutPoint,
        signature: signature,
        checklistTemplateId: checklistTemplateId,
      );
    }

    ChecklistTemplate buildTemplate() {
      return ChecklistTemplate.tryCreate(
        id: 'tpl-1',
        title: 'Instalação',
        items: [
          ChecklistItem.tryCreate(id: 'i1', title: 'Verificar pressão', order: 0)
              .getOrNull()!,
          ChecklistItem.tryCreate(id: 'i2', title: 'Limpeza', order: 1)
              .getOrNull()!,
          ChecklistItem.tryCreate(id: 'i3', title: 'Teste final', order: 2)
              .getOrNull()!,
        ],
      ).getOrNull()!;
    }

    test('monta ReportData completo para OS concluída', () {
      final workOrder = buildCompletedWorkOrder();
      final customer = Customer.tryCreate(
        id: 'cust-1',
        name: 'Padaria Estrela',
        document: '52998224725',
        whatsapp: '11987654321',
        email: '',
        notes: '',
      ).getOrNull()!;
      final profile = TechnicianProfile.tryCreate(
        commercialName: 'ClimaFrio Refrigeração',
        whatsapp: '11988887777',
      ).getOrNull()!;
      final template = buildTemplate();
      final answers = [
        ChecklistAnswer.tryCreate(
          workOrderId: 'wo-1',
          itemId: 'i1',
          status: ChecklistAnswerStatus.conforme,
          notes: 'Ok',
        ).getOrNull()!,
        ChecklistAnswer.tryCreate(
          workOrderId: 'wo-1',
          itemId: 'i2',
          status: ChecklistAnswerStatus.naoConforme,
          notes: '',
        ).getOrNull()!,
        ChecklistAnswer.tryCreate(
          workOrderId: 'wo-1',
          itemId: 'i3',
          status: ChecklistAnswerStatus.naoAplica,
          notes: 'N/A',
        ).getOrNull()!,
      ];

      final data = ReportDataAssembler.assemble(
        workOrder: workOrder,
        customer: customer,
        technicianProfile: profile,
        template: template,
        answers: answers,
        technicianLogoBytes: Uint8List.fromList(const [1, 2, 3]),
      );

      expect(data.workOrderId, 'wo-1');
      expect(data.status, 'COMPLETED');
      expect(data.serviceDescription, 'Instalação de ar-condicionado');
      expect(data.scheduledDateFormatted, '24/11/2026 09:00');
      expect(data.completedDateFormatted, '24/11/2026 11:30');
      expect(data.customerName, 'Padaria Estrela');
      expect(data.customerDocument, '52998224725');
      expect(data.customerPhone, '11987654321');
      expect(data.technicianName, 'ClimaFrio Refrigeração');
      expect(data.technicianCommercialName, 'ClimaFrio Refrigeração');
      expect(data.technicianPhone, '11988887777');
      expect(data.technicianLogoBytes, Uint8List.fromList(const [1, 2, 3]));
      expect(data.estimatedAmountFormatted, contains('850,00'));
      expect(data.checklistItems, hasLength(3));
      expect(data.checklistItems[0].statusDescription, 'Conforme');
      expect(data.checklistItems[0].notes, 'Ok');
      expect(data.checklistItems[1].statusDescription, 'Não conforme');
      expect(data.checklistItems[1].notes, isNull);
      expect(data.checklistItems[2].statusDescription, 'Não se aplica');
      expect(data.photos, isEmpty);
      expect(data.signaturePngBytes, isNotNull);
      expect(data.signerName, 'João Cliente');
      expect(data.signerDocument, '12345678900');
      expect(data.checkInGpsFormatted, '-23.55050, -46.63330');
      expect(data.checkOutGpsFormatted, '-23.55060, -46.63340');
      expect(data.locationAddress, isNull);
    });

    test('monta ReportData com dados opcionais ausentes', () {
      final workOrder = WorkOrder.restore(
        id: 'wo-2',
        customerId: 'cust-2',
        serviceDescription: 'Visita técnica',
        scheduledAt: DateTime.utc(2026, 11, 25, 8, 0),
        estimatedValue: Money.fromMinorUnits(0, currencyCode: 'BRL', scale: 2),
        status: WorkOrderStatus.completed,
      );

      final data = ReportDataAssembler.assemble(
        workOrder: workOrder,
        customer: null,
        technicianProfile: null,
        template: null,
        answers: const [],
      );

      expect(data.workOrderId, 'wo-2');
      expect(data.status, 'COMPLETED');
      expect(data.customerName, isNull);
      expect(data.customerDocument, isNull);
      expect(data.customerPhone, isNull);
      expect(data.technicianName, isNull);
      expect(data.technicianPhone, isNull);
      expect(data.completedDateFormatted, isNull);
      expect(data.checklistItems, isEmpty);
      expect(data.photos, isEmpty);
      expect(data.signaturePngBytes, isNull);
      expect(data.signerName, isNull);
      expect(data.signerDocument, isNull);
      expect(data.checkInGpsFormatted, isNull);
      expect(data.checkOutGpsFormatted, isNull);
    });

    test('mapeia item sem resposta como Sem resposta', () {
      final workOrder = buildCompletedWorkOrder();
      final template = buildTemplate();

      final data = ReportDataAssembler.assemble(
        workOrder: workOrder,
        customer: null,
        technicianProfile: null,
        template: template,
        answers: const [],
      );

      expect(data.checklistItems, hasLength(3));
      expect(
        data.checklistItems.every((i) => i.statusDescription == 'Sem resposta'),
        isTrue,
      );
    });
  });
}
