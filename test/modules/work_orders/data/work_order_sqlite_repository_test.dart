import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:kortex_lib/core/models/money.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/core/security/document_at_rest_cipher_port.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
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

final class _FakeDocumentAtRestCipher implements IDocumentAtRestCipher {
  @override
  Future<IResult<String, ValidationError>> encrypt(String plainText) async =>
      Success('enc:v1:${base64Encode(utf8.encode(plainText))}');

  @override
  Future<IResult<String, ValidationError>> decrypt(String cipherText) async {
    const prefix = 'enc:v1:';
    if (!cipherText.startsWith(prefix)) {
      return const Failure(
        ValidationError(code: 'ERR_TEST_CIPHER', message: 'invalid'),
      );
    }
    return Success(
      utf8.decode(base64Decode(cipherText.substring(prefix.length))),
    );
  }
}

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
        dbVersion: 10,
        migrations: [
          WorkOrderMigration.v3(),
          WorkOrderMigration.v4(),
          WorkOrderMigration.v5(),
          WorkOrderMigration.v6(),
          WorkOrderMigration.v7(),
          WorkOrderMigration.v9(),
          WorkOrderMigration.v10(),
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
        estimatedValue: Money.fromMinorUnits(
          15000,
          currencyCode: 'BRL',
          scale: 2,
        ),
      ).getOrNull()!;
      final saved = await repo.save(wo);
      expect(
        saved.isSuccess,
        isTrue,
        reason: saved.isFailure ? saved.getOrNullFailure().toString() : '',
      );
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
        estimatedValue: Money.fromMinorUnits(
          15000,
          currencyCode: 'BRL',
          scale: 2,
        ),
      ).getOrNull()!;
      final point = GeoPoint.tryCreate(
        latitude: -23.5,
        longitude: -46.6,
        timestampUtc: DateTime.utc(2026, 11, 21, 12),
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
        estimatedValue: Money.fromMinorUnits(
          15000,
          currencyCode: 'BRL',
          scale: 2,
        ),
      ).getOrNull()!;
      final cancelled = wo.cancel('Cliente ausente').getOrNull()!;
      await repo.save(cancelled);

      final all = await repo.findAll();
      final loaded = all.getOrNull()!.first;
      expect(loaded.status, WorkOrderStatus.cancelled);
      expect(loaded.cancellationReason, 'Cliente ausente');
    });

    test('UC-03.04 - persiste pausa e retomada', () async {
      final wo = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(
          15000,
          currencyCode: 'BRL',
          scale: 2,
        ),
      ).getOrNull()!;
      final point = GeoPoint.tryCreate(
        latitude: -23.5,
        longitude: -46.6,
        timestampUtc: DateTime.utc(2026, 11, 21, 12),
      ).getOrNull()!;
      final inProgress = wo.startService(LocationCaptured(point)).getOrNull()!;
      final paused = inProgress.pause('Aguardando peça').getOrNull()!;
      await repo.save(paused);
      var loaded = (await repo.findAll()).getOrNull()!.first;
      expect(loaded.status, WorkOrderStatus.paused);
      expect(loaded.pauseReason, 'Aguardando peça');

      final resumed = paused.resume().getOrNull()!;
      await repo.save(resumed);
      loaded = (await repo.findAll()).getOrNull()!.first;
      expect(loaded.status, WorkOrderStatus.inProgress);
      expect(loaded.pauseReason, isNull);
    });

    test('UC-03.05 - persiste conclusão e restaura assinatura/checkout (INV-SEC-24)', () async {
      final wo = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(
          15000,
          currencyCode: 'BRL',
          scale: 2,
        ),
      ).getOrNull()!;
      final point = GeoPoint.tryCreate(
        latitude: -23.5,
        longitude: -46.6,
        timestampUtc: DateTime.utc(2026, 11, 21, 12),
      ).getOrNull()!;
      final inProgress = wo.startService(LocationCaptured(point)).getOrNull()!;
      await repo.save(inProgress);
      final sig = DigitalSignature.tryCreate(
        signerName: 'Carlos Silva',
        signatureBytes: Uint8List.fromList([
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
          0,
          0,
          0,
          13,
        ]),
      ).getOrNull()!;
      final proof = ChecklistCompletionProof.tryCreate(
        mandatoryTotal: 0,
        answeredMandatory: 0,
      ).getOrNull()!;
      final completed = inProgress
          .complete(signature: sig, checkOut: point, checklistProof: proof)
          .getOrNull()!;
      final saved = await repo.save(completed);
      expect(saved.isSuccess, isTrue);

      final loaded = (await repo.findAll()).getOrNull()!.first;
      expect(loaded.status, WorkOrderStatus.completed);
      expect(loaded.checkOut, isNotNull);
      expect(loaded.signature, isNotNull);
      expect(loaded.signature.toString(), contains('redacted'));
      expect(loaded.toString(), contains('redacted'));
    });

    test(
      'UC-03.05 - repo bloqueia update em OS COMPLETED (INV-SEC-23)',
      () async {
        final wo = WorkOrder.tryCreate(
          id: 'wo1',
          customerId: 'c1',
          serviceDescription: 'Manutenção',
          scheduledAt: DateTime.utc(2026, 11, 22, 14),
          estimatedValue: Money.fromMinorUnits(
            15000,
            currencyCode: 'BRL',
            scale: 2,
          ),
        ).getOrNull()!;
        final point = GeoPoint.tryCreate(
          latitude: -23.5,
          longitude: -46.6,
          timestampUtc: DateTime.utc(2026, 11, 21, 12),
        ).getOrNull()!;
        final inProgress = wo
            .startService(LocationCaptured(point))
            .getOrNull()!;
        await repo.save(inProgress);
        final sig = DigitalSignature.tryCreate(
          signerName: 'Carlos Silva',
          signatureBytes: Uint8List.fromList([
            137,
            80,
            78,
            71,
            13,
            10,
            26,
            10,
            0,
            0,
            0,
            13,
          ]),
        ).getOrNull()!;
        final proof = ChecklistCompletionProof.tryCreate(
          mandatoryTotal: 0,
          answeredMandatory: 0,
        ).getOrNull()!;
        final completed = inProgress
            .complete(signature: sig, checkOut: point, checklistProof: proof)
            .getOrNull()!;
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
      },
    );

    test(
      'UC-03.05 - repo bloqueia insert fabricado de OS COMPLETED (INV-SEC-23)',
      () async {
        final point = GeoPoint.tryCreate(
          latitude: -23.5,
          longitude: -46.6,
          timestampUtc: DateTime.utc(2026, 11, 21, 12),
        ).getOrNull()!;
        final sig = DigitalSignature.tryCreate(
          signerName: 'Carlos Silva',
          signatureBytes: Uint8List.fromList([
            137,
            80,
            78,
            71,
            13,
            10,
            26,
            10,
            0,
            0,
            0,
            13,
          ]),
        ).getOrNull()!;
        final proof = ChecklistCompletionProof.tryCreate(
          mandatoryTotal: 0,
          answeredMandatory: 0,
        ).getOrNull()!;
        final fabricated = WorkOrder.restore(
          id: 'wo-fabricated',
          customerId: 'c1',
          serviceDescription: 'Fabricada',
          scheduledAt: DateTime.utc(2026, 11, 22, 14),
          estimatedValue: Money.fromMinorUnits(
            15000,
            currencyCode: 'BRL',
            scale: 2,
          ),
          status: WorkOrderStatus.completed,
          checkIn: null,
          cancellationReason: null,
          checkOut: point,
          signature: sig,
          checklistProof: proof,
        );
        final res = await repo.save(fabricated);
        expect(res.isFailure, isTrue);
        expect(res.getOrNullFailure()!.code, 'ERR_OS_IMUTAVEL');
        final all = await repo.findAll();
        expect(all.getOrNull()!, isEmpty);
      },
    );

    test('UC-04.07 - persiste e restaura checklistTemplateId', () async {
      final wo = WorkOrder.tryCreate(
        id: 'wo-tpl',
        customerId: 'c1',
        serviceDescription: 'Instalação',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(
          10000,
          currencyCode: 'BRL',
          scale: 2,
        ),
        checklistTemplateId: 'tpl-1',
      ).getOrNull()!;
      expect(wo.checklistTemplateId, 'tpl-1');

      final saved = await repo.save(wo);
      expect(saved.isSuccess, isTrue);

      final loaded = (await repo.findAll()).getOrNull()!.first;
      expect(loaded.checklistTemplateId, 'tpl-1');
    });

    test('UC-04.08/C-01 - repo fail-closed ao persistir documentNumber sem proteção em repouso', () async {
      final wo = WorkOrder.tryCreate(
        id: 'wo-sig-doc',
        customerId: 'c1',
        serviceDescription: 'Manutenção',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(
          15000,
          currencyCode: 'BRL',
          scale: 2,
        ),
      ).getOrNull()!;
      final point = GeoPoint.tryCreate(
        latitude: -23.5,
        longitude: -46.6,
        timestampUtc: DateTime.utc(2026, 11, 21, 12),
      ).getOrNull()!;
      final inProgress = wo.startService(LocationCaptured(point)).getOrNull()!;
      await repo.save(inProgress);
      final sig = DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList([
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
          0,
          0,
          0,
          13,
        ]),
        signerName: 'Carlos Silva',
        documentNumber: '12345678909',
      ).getOrNull()!;
      final proof = ChecklistCompletionProof.tryCreate(
        mandatoryTotal: 0,
        answeredMandatory: 0,
      ).getOrNull()!;
      final completed = inProgress
          .complete(signature: sig, checkOut: point, checklistProof: proof)
          .getOrNull()!;
      final res = await repo.save(completed);
      expect(res.isFailure, isTrue);
      expect(
        res.getOrNullFailure()!.code,
        'ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL',
      );

      final reloaded = (await repo.findAll()).getOrNull()!.firstWhere(
        (candidate) => candidate.id == 'wo-sig-doc',
      );
      expect(reloaded.status, WorkOrderStatus.inProgress);
      expect(reloaded.signature, isNull);
      expect(reloaded.checkOut, isNull);
    });

    test('D-01/C-01 - persiste e reidrata documentNumber cifrado em repouso', () async {
      final cipher = _FakeDocumentAtRestCipher();
      final secureRepo = WorkOrderSqliteRepository(
        provider: provider,
        documentCipher: cipher,
      );
      final wo = WorkOrder.tryCreate(
        id: 'wo-sig-doc-enc',
        customerId: 'c1',
        serviceDescription: 'Manutenção com documento',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(
          15000,
          currencyCode: 'BRL',
          scale: 2,
        ),
      ).getOrNull()!;
      final point = GeoPoint.tryCreate(
        latitude: -23.5,
        longitude: -46.6,
        timestampUtc: DateTime.utc(2026, 11, 21, 12),
      ).getOrNull()!;
      final inProgress = wo.startService(LocationCaptured(point)).getOrNull()!;
      await secureRepo.save(inProgress);
      final sig = DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13]),
        signerName: 'Carlos Silva',
        documentNumber: '12345678909',
      ).getOrNull()!;
      final proof = ChecklistCompletionProof.tryCreate(
        mandatoryTotal: 0,
        answeredMandatory: 0,
      ).getOrNull()!;
      final completed = inProgress
          .complete(signature: sig, checkOut: point, checklistProof: proof)
          .getOrNull()!;

      final res = await secureRepo.save(completed);
      expect(res.isSuccess, isTrue);

      final db = await provider.db;
      final rows = await db.query(
        WorkOrderMigration.table,
        columns: ['signature_document_number'],
        where: 'id = ?',
        whereArgs: ['wo-sig-doc-enc'],
      );
      final rawDoc = rows.single['signature_document_number'] as String?;
      expect(rawDoc, isNotNull);
      expect(rawDoc, startsWith('enc:v1:'));
      expect(rawDoc, isNot(contains('12345678909')));

      final loaded = (await secureRepo.findAll()).getOrNull()!.firstWhere(
        (candidate) => candidate.id == 'wo-sig-doc-enc',
      );
      expect(loaded.signature?.documentNumber, '12345678909');
    });

    test('UC-04.08/A3 - reidratação de assinatura corrompida falha fail-closed sem PII', () async {
      final db = await provider.db;
      await db.insert(WorkOrderMigration.table, {
        'id': 'wo-bad-sig',
        'customer_id': 'c1',
        'service_description': 'Teste',
        'scheduled_at': DateTime.utc(2026, 11, 22, 14).toIso8601String(),
        'estimated_value_minor': 1000,
        'estimated_value_currency': 'BRL',
        'estimated_value_scale': 2,
        'status': 'IN_PROGRESS',
        'created_at': DateTime.utc(2026, 11, 22, 10).toIso8601String(),
        'updated_at': DateTime.utc(2026, 11, 22, 10).toIso8601String(),
        'signature_name': 'Nome Sensível',
        'signature_image_base64': '%%%not-base64%%%',
        'signature_signed_at_utc': null,
        'signature_document_number': null,
      });
      final res = await repo.findAll();
      expect(res.isFailure, isTrue);
      final err = res.getOrNullFailure()!;
      expect(err.code, 'ERR_OS_DADOS_INVALIDOS');
      expect(err.message, isNot(contains('Nome Sensível')));
      expect(err.message, isNot(contains('not-base64')));
    });
  });
}
