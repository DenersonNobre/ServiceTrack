import 'dart:io';

import 'dart:convert';

import 'package:dnolib/core/models/money.dart';
import 'package:dnolib/sqlite/sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/work_orders/data/work_order_migration.dart';
import 'package:service_track/modules/work_orders/data/work_order_sqlite_repository.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/check_in_record.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/checklist_completion_proof.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/digital_signature.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/location_capture.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order_status.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('WorkOrderSqliteRepository', () {
    late SqliteProvider provider;
    late WorkOrderSqliteRepository repo;
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('st_wo_');
      await databaseFactoryFfi.setDatabasesPath(dir.path);
      provider = SqliteProvider(
        dbName: 'test_wo.db',
        dbVersion: 6,
        migrations: [
          WorkOrderMigration.v3(),
          WorkOrderMigration.v4(),
          WorkOrderMigration.v5(),
          WorkOrderMigration.v6(),
        ],
        factory: databaseFactoryFfi,
      );
      repo = WorkOrderSqliteRepository(provider: provider);
    });

    tearDown(() async {
      await provider.close();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('save e findAll', () async {
      final wo = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(15000, currencyCode: 'BRL', scale: 2),
      ).getOrNull()!;
      final saved = await repo.save(wo);
      expect(saved.isSuccess, isTrue, reason: saved.isFailure ? saved.getOrNullFailure().toString() : '');
      final all = await repo.findAll();
      expect(all.getOrNull()!.length, 1);
      expect(all.getOrNull()!.first.serviceDescription, 'Manutenção');
    });

    test('UC-03.03 - persiste check-in GPS e restaura', () async {
      final wo = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(15000, currencyCode: 'BRL', scale: 2),
      ).getOrNull()!;
      final point = GeoPoint.tryCreate(
        latitude: -23.5, longitude: -46.6, timestampUtc: DateTime.utc(2026, 11, 21, 12),
      ).getOrNull()!;
      final started = wo.startService(LocationCaptured(point)).getOrNull()!;
      await repo.save(started);

      final all = await repo.findAll();
      final loaded = all.getOrNull()!.first;
      expect(loaded.status, WorkOrderStatus.inProgress);
      expect(loaded.checkIn, isA<CheckInGps>());
    });

    test('UC-03.04 - persiste cancelamento com justificativa', () async {
      final wo = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(15000, currencyCode: 'BRL', scale: 2),
      ).getOrNull()!;
      final cancelled = wo.cancel('Cliente ausente').getOrNull()!;
      await repo.save(cancelled);

      final all = await repo.findAll();
      final loaded = all.getOrNull()!.first;
      expect(loaded.status, WorkOrderStatus.cancelled);
      expect(loaded.cancellationReason, 'Cliente ausente');
    });

    test('UC-03.05 - persiste conclusão e restaura assinatura/checkout (INV-SEC-24)', () async {
      final wo = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(15000, currencyCode: 'BRL', scale: 2),
      ).getOrNull()!;
      final point = GeoPoint.tryCreate(
        latitude: -23.5, longitude: -46.6, timestampUtc: DateTime.utc(2026, 11, 21, 12),
      ).getOrNull()!;
      final inProgress = wo.startService(LocationCaptured(point)).getOrNull()!;
      final sig = DigitalSignature.tryCreate(
        signerName: 'Carlos Silva',
        imageBase64: base64Encode(List<int>.filled(64, 1)),
      ).getOrNull()!;
      final proof = ChecklistCompletionProof.tryCreate(mandatoryTotal: 0, answeredMandatory: 0).getOrNull()!;
      final completed = inProgress.complete(signature: sig, checkOut: point, checklistProof: proof).getOrNull()!;
      final saved = await repo.save(completed);
      expect(saved.isSuccess, isTrue);

      final loaded = (await repo.findAll()).getOrNull()!.first;
      expect(loaded.status, WorkOrderStatus.completed);
      expect(loaded.checkOut, isNotNull);
      expect(loaded.signature, isNotNull);
      expect(loaded.signature.toString(), contains('redacted'));
      expect(loaded.toString(), contains('redacted'));
    });

    test('UC-03.05 - repo bloqueia update em OS COMPLETED (INV-SEC-23)', () async {
      final wo = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(15000, currencyCode: 'BRL', scale: 2),
      ).getOrNull()!;
      final point = GeoPoint.tryCreate(
        latitude: -23.5, longitude: -46.6, timestampUtc: DateTime.utc(2026, 11, 21, 12),
      ).getOrNull()!;
      final inProgress = wo.startService(LocationCaptured(point)).getOrNull()!;
      final sig = DigitalSignature.tryCreate(
        signerName: 'Carlos Silva',
        imageBase64: base64Encode(List<int>.filled(64, 1)),
      ).getOrNull()!;
      final proof = ChecklistCompletionProof.tryCreate(mandatoryTotal: 0, answeredMandatory: 0).getOrNull()!;
      final completed = inProgress.complete(signature: sig, checkOut: point, checklistProof: proof).getOrNull()!;
      await repo.save(completed);

      final tampered = WorkOrder.restore(
        id: completed.id,
        customerId: completed.customerId,
        serviceDescription: 'Adulterado',
        scheduledAt: completed.scheduledAt,
        estimatedValue: completed.estimatedValue,
        status: WorkOrderStatus.completed,
        checkIn: completed.checkIn,
        cancellationReason: completed.cancellationReason,
        checkOut: completed.checkOut,
        signature: completed.signature,
        checklistProof: completed.checklistProof,
      );
      final res = await repo.save(tampered);
      expect(res.isFailure, isTrue);
      expect(res.getOrNullFailure()!.code, 'ERR_OS_IMUTAVEL');

      final loaded = (await repo.findAll()).getOrNull()!.first;
      expect(loaded.serviceDescription, 'Manutenção');
    });
  });
}
