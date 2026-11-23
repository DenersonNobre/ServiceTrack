// Testes de cancelamento de OS (UC-03.04).
//
// SRP: validar transições e justificativa obrigatória no domínio.

import 'package:kortex_lib/core/models/money.dart';
import 'package:flutter_test/flutter_test.dart';
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
        latitude: -23.5, longitude: -46.6, timestampUtc: DateTime.utc(2026, 11, 21, 12),
      ).getOrNull()!;

  group('WorkOrder.cancel (UC-03.04)', () {
    test('cancela OS agendada com justificativa', () {
      final r = scheduled().cancel('Cliente pediu remarcação');
      expect(r.isSuccess, isTrue);
      final wo = r.getOrNull()!;
      expect(wo.status, WorkOrderStatus.cancelled);
      expect(wo.cancellationReason, 'Cliente pediu remarcação');
    });

    test('rejeita cancelamento sem justificativa', () {
      final r = scheduled().cancel('   ');
      expect(r.isFailure, isTrue);
      expect(r.getOrNullFailure()!.code, 'ERR_OS_JUSTIFICATIVA_OBRIGATORIA');
    });

    test('rejeita cancelamento de OS concluída/cancelada', () {
      final inProgress = scheduled().startService(LocationCaptured(point())).getOrNull()!;
      final cancelled = inProgress.cancel('Motivo').getOrNull()!;
      final r = cancelled.cancel('Outro');
      expect(r.isFailure, isTrue);
      expect(r.getOrNullFailure()!.code, 'ERR_OS_TRANSICAO_INVALIDA');
    });

    test('rejeita cancelamento de OS concluída (INV-06)', () {
      final completed = WorkOrder.restore(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(1000, currencyCode: 'BRL', scale: 2),
        status: WorkOrderStatus.completed,
      );
      final r = completed.cancel('Motivo');
      expect(r.isFailure, isTrue);
      expect(r.getOrNullFailure()!.code, 'ERR_OS_TRANSICAO_INVALIDA');
    });
  });
}
