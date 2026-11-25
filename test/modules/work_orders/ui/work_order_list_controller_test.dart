import 'dart:typed_data';

import 'package:kortex_lib/core/models/money.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/work_orders/data/memory_work_order_repository.dart';
import 'package:service_track/modules/work_orders/domain/ports/checklist_proof_port.dart';
import 'package:service_track/modules/work_orders/domain/ports/location_service_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/checklist_completion_proof.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/digital_signature.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/location_capture.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/work_order_status.dart';
import 'package:service_track/modules/evidences/domain/ports/evidence_failure_codes.dart';
import 'package:service_track/modules/settings/.index.dart';
import 'package:service_track/modules/work_orders/domain/ports/work_order_failure_codes.dart';
import 'package:service_track/modules/work_orders/ui/list/work_order_list_controller.dart';

class _FailingSettingsRepository implements ISettingsRepositoryPort {
  @override
  Future<IResult<SettingsSnapshot, ValidationError>> load() async =>
      const Failure(
        ValidationError(
          code: 'ERR_CONFIGURACAO_PERSISTENCIA',
          message: 'Falha de configuração.',
        ),
      );

  @override
  Future<IResult<SettingsSnapshot, ValidationError>> update(
    SettingKey key,
    Object value,
  ) => load();
}

Future<MemoryWorkOrderRepository> _inProgressRepo() async {
  final repo = MemoryWorkOrderRepository();
  final base = WorkOrder.tryCreate(
    id: 'wo1',
    customerId: 'c1',
    serviceDescription: 'Instalação',
    scheduledAt: DateTime.utc(2026, 11, 22, 14),
    estimatedValue: Money.fromMinorUnits(1000, currencyCode: 'BRL', scale: 2),
    checklistTemplateId: 'tpl-1',
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

DigitalSignature _signature({String? documentNumber}) =>
    DigitalSignature.tryCreate(
      signerName: 'Carlos',
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
      documentNumber: documentNumber,
    ).getOrNull()!;

class _FakeLocationService implements ILocationServicePort {
  @override
  Future<IResult<GeoPoint, ValidationError>> getCurrentLocation() async {
    return const Failure(
      ValidationError(code: 'ERR_LOCALIZACAO_INDISPONIVEL', message: 'x'),
    );
  }
}

class _SuccessLocationService implements ILocationServicePort {
  @override
  Future<IResult<GeoPoint, ValidationError>> getCurrentLocation() async {
    return GeoPoint.tryCreate(
      latitude: -23.5,
      longitude: -46.6,
      timestampUtc: DateTime.utc(2026, 11, 21, 12),
    );
  }
}

class _FakeChecklistProofPort implements IChecklistProofPort {
  _FakeChecklistProofPort(this.result);
  final IResult<ChecklistCompletionProof, ValidationError> result;
  String? lastWorkOrderId;
  String? lastTemplateId;

  bool? lastRequireTemplate;
  @override
  Future<IResult<ChecklistCompletionProof, ValidationError>> getProof({
    required String workOrderId,
    required String? templateId,
    bool requireTemplate = true,
  }) async {
    lastWorkOrderId = workOrderId;
    lastTemplateId = templateId;
    lastRequireTemplate = requireTemplate;
    return result;
  }
}

GetSettings _settings([MemorySettingsRepository? repository]) =>
    GetSettings(repository: repository ?? MemorySettingsRepository());

void main() {
  WorkOrder wo(String id, WorkOrderStatus status, DateTime at) =>
      WorkOrder.restore(
        id: id,
        customerId: 'c1',
        serviceDescription: 'OS $id',
        scheduledAt: at,
        estimatedValue: Money.fromMinorUnits(
          1000,
          currencyCode: 'BRL',
          scale: 2,
        ),
        status: status,
      );

  test('UC-03.02 - filtra ordens por chip', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10).toUtc();
    final tomorrow = today.add(const Duration(days: 1));
    final repo = MemoryWorkOrderRepository();
    await repo.save(wo('1', WorkOrderStatus.scheduled, today));
    await repo.save(wo('2', WorkOrderStatus.inProgress, tomorrow));
    await repo.save(wo('3', WorkOrderStatus.completed, today));

    final c = WorkOrderListController(
      repository: repo,
      locationService: _FakeLocationService(),
      checklistProofPort: _FakeChecklistProofPort(
        ChecklistCompletionProof.tryCreate(
          mandatoryTotal: 0,
          answeredMandatory: 0,
        ),
      ),
      getSettings: _settings(),
    );
    await c.load();

    c.filter.value = WorkOrderListFilter.today;
    expect(c.filteredItems.map((e) => e.id).toSet(), {'1', '3'});

    c.filter.value = WorkOrderListFilter.scheduled;
    expect(c.filteredItems.map((e) => e.id), ['1']);

    c.filter.value = WorkOrderListFilter.inProgress;
    expect(c.filteredItems.map((e) => e.id), ['2']);

    c.filter.value = WorkOrderListFilter.completed;
    expect(c.filteredItems.map((e) => e.id), ['3']);

    c.filter.value = WorkOrderListFilter.all;
    expect(c.filteredItems.length, 3);
    c.dispose();
  });

  test(
    'UC-04.07/D-05 - conclusão usa prova real do checklist via porta',
    () async {
      final repo = MemoryWorkOrderRepository();
      final base = WorkOrder.tryCreate(
        id: 'wo1',
        customerId: 'c1',
        serviceDescription: 'Instalação',
        scheduledAt: DateTime.utc(2026, 11, 22, 14),
        estimatedValue: Money.fromMinorUnits(
          1000,
          currencyCode: 'BRL',
          scale: 2,
        ),
        checklistTemplateId: 'tpl-1',
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

      final proofPort = _FakeChecklistProofPort(
        const Failure(
          ValidationError(
            code: 'ERR_CHECKLIST_INCOMPLETO',
            message: 'Checklist obrigatório incompleto.',
          ),
        ),
      );
      final c = WorkOrderListController(
        repository: repo,
        locationService: _SuccessLocationService(),
        checklistProofPort: proofPort,
        getSettings: _settings(),
      );
      await c.load();
      final sig = DigitalSignature.tryCreate(
        signerName: 'Carlos',
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

      final result = await c.completeWorkOrder('wo1', signature: sig);
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, 'ERR_CHECKLIST_INCOMPLETO');
      expect(proofPort.lastWorkOrderId, 'wo1');
      expect(proofPort.lastTemplateId, 'tpl-1');
      expect(proofPort.lastRequireTemplate, isTrue);

      final okPort = _FakeChecklistProofPort(
        ChecklistCompletionProof.tryCreate(
          mandatoryTotal: 1,
          answeredMandatory: 1,
        ),
      );
      final c2 = WorkOrderListController(
        repository: repo,
        locationService: _SuccessLocationService(),
        checklistProofPort: okPort,
        getSettings: _settings(),
      );
      await c2.load();
      final ok = await c2.completeWorkOrder('wo1', signature: sig);
      expect(ok.isSuccess, isTrue);
      expect(ok.getOrNull()!.status, WorkOrderStatus.completed);
      c.dispose();
      c2.dispose();
    },
  );

  test('UC-07.03/SEC-08 - política false não relaxa INV-03', () async {
    final repo = await _inProgressRepo();
    final settings = MemorySettingsRepository(
      SettingsSnapshot({SettingKey.requireChecklistTemplate: false}),
    );
    final proofPort = _FakeChecklistProofPort(
      const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.checklistIncomplete,
          message: 'Checklist obrigatório incompleto.',
        ),
      ),
    );
    final c = WorkOrderListController(
      repository: repo,
      locationService: _SuccessLocationService(),
      checklistProofPort: proofPort,
      getSettings: GetSettings(repository: settings),
    );
    await c.load();

    final result = await c.completeWorkOrder('wo1', signature: _signature());

    expect(result.isFailure, isTrue);
    expect(
      result.getOrNullFailure()!.code,
      WorkOrderFailureCodes.checklistIncomplete,
    );
    expect(proofPort.lastRequireTemplate, isFalse);
    c.dispose();
  });

  test('UC-07.03/SEC-03 - falha ao ler settings aborta fail-closed', () async {
    final repo = await _inProgressRepo();
    final proofPort = _FakeChecklistProofPort(
      ChecklistCompletionProof.tryCreate(
        mandatoryTotal: 1,
        answeredMandatory: 1,
      ),
    );
    final c = WorkOrderListController(
      repository: repo,
      locationService: _SuccessLocationService(),
      checklistProofPort: proofPort,
      getSettings: GetSettings(repository: _FailingSettingsRepository()),
    );
    await c.load();

    final result = await c.completeWorkOrder('wo1', signature: _signature());

    expect(result.isFailure, isTrue);
    expect(result.getOrNullFailure()!.code, 'ERR_CONFIGURACAO_PERSISTENCIA');
    expect(proofPort.lastRequireTemplate, isNull);
    c.dispose();
  });

  test(
    'UC-07.03/SEC-02 - documento exigido pela política é validado na operação',
    () async {
      final repo = await _inProgressRepo();
      final settings = MemorySettingsRepository(
        SettingsSnapshot({SettingKey.requireReceiverDocument: true}),
      );
      final c = WorkOrderListController(
        repository: repo,
        locationService: _SuccessLocationService(),
        checklistProofPort: _FakeChecklistProofPort(
          ChecklistCompletionProof.tryCreate(
            mandatoryTotal: 1,
            answeredMandatory: 1,
          ),
        ),
        getSettings: GetSettings(repository: settings),
        documentAtRestProtectionAvailable: true,
      );
      await c.load();

      final result = await c.completeWorkOrder('wo1', signature: _signature());

      expect(result.isFailure, isTrue);
      expect(
        result.getOrNullFailure()!.code,
        EvidenceFailureCodes.missingSignerDocument,
      );
      c.dispose();
    },
  );

  test(
    'UC-07.03/SEC-04 - documento não é persistido sem proteção em repouso',
    () async {
      final repo = await _inProgressRepo();
      final settings = MemorySettingsRepository(
        SettingsSnapshot({SettingKey.requireReceiverDocument: true}),
      );
      final c = WorkOrderListController(
        repository: repo,
        locationService: _SuccessLocationService(),
        checklistProofPort: _FakeChecklistProofPort(
          ChecklistCompletionProof.tryCreate(
            mandatoryTotal: 1,
            answeredMandatory: 1,
          ),
        ),
        getSettings: GetSettings(repository: settings),
      );
      await c.load();

      final result = await c.completeWorkOrder(
        'wo1',
        signature: _signature(documentNumber: '12345678909'),
      );

      expect(result.isFailure, isTrue);
      expect(
        result.getOrNullFailure()!.code,
        WorkOrderFailureCodes.signatureDocumentProtectionUnavailable,
      );
      final reloaded = (await repo.findAll()).getOrNull()!.firstWhere(
        (candidate) => candidate.id == 'wo1',
      );
      expect(reloaded.status, WorkOrderStatus.inProgress);
      expect(reloaded.signature, isNull);
      c.dispose();
    },
  );
}
