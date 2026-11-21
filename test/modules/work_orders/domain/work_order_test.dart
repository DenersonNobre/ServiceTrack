import 'package:dnolib/core/models/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order_status.dart';

void main() {
  group('WorkOrder', () {
    test('UC-03.01 - cria OS agendada com valor estimado', () {
      final r = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção de ar-condicionado',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(15000, currencyCode: 'BRL', scale: 2),
      );
      expect(r.isSuccess, isTrue);
      final wo = r.getOrNull()!;
      expect(wo.status, WorkOrderStatus.scheduled);
      expect(wo.estimatedValue.minorUnits, BigInt.from(15000));
    });

    test('rejeita descrição vazia', () {
      final r = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: '  ',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(0, currencyCode: 'BRL', scale: 2),
      );
      expect(r.isFailure, isTrue);
    });
  });
}
