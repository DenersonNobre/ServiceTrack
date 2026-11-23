import 'package:kortex_lib/core/models/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/check_in_bypass_reason.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/check_in_record.dart';
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

  group('WorkOrder.startService (UC-03.03, INV-01/INV-02/INV-SEC-17/19)', () {
    test('SCHEDULED + captura válida -> IN_PROGRESS com check-in GPS', () {
      final r = scheduled().startService(LocationCaptured(point()));
      expect(r.isSuccess, isTrue);
      final wo = r.getOrNull()!;
      expect(wo.status, WorkOrderStatus.inProgress);
      expect(wo.checkIn, isA<CheckInGps>());
    });

    test('SCHEDULED + bypass tipado -> IN_PROGRESS com auditoria', () {
      final r = scheduled().startService(
        const LocationBypassed(reason: CheckInBypassReason.gpsUnavailable),
      );
      expect(r.isSuccess, isTrue);
      final wo = r.getOrNull()!;
      expect(wo.status, WorkOrderStatus.inProgress);
      final checkIn = wo.checkIn! as CheckInBypassed;
      expect(checkIn.reason, CheckInBypassReason.gpsUnavailable);
      expect(checkIn.timestampUtc.isUtc, isTrue);
    });

    test('transição ilegal IN_PROGRESS -> falha INV-01', () {
      final started = scheduled().startService(LocationCaptured(point())).getOrNull()!;
      final r = started.startService(LocationCaptured(point()));
      expect(r.isFailure, isTrue);
      expect(r.getOrNullFailure()!.code, 'ERR_OS_TRANSICAO_INVALIDA');
    });
  });
}
