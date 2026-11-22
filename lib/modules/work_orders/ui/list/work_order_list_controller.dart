// Controller da lista de OS (UC-03.01 base, UC-03.02 filtros, UC-03.03 check-in).
//
// SRP: carregar, filtrar e iniciar atendimento de OS. Não renderiza UI.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../../evidences/domain/ports/evidence_failure_codes.dart';
import '../../../settings/domain/.index.dart';
import '../../../settings/features/.index.dart';
import '../../domain/ports/checklist_proof_port.dart';
import '../../domain/ports/location_service_port.dart';
import '../../domain/ports/work_order_failure_codes.dart';
import '../../domain/ports/work_order_repository_port.dart';
import '../../domain/value_objects/check_in_bypass_reason.dart';
import '../../domain/value_objects/checklist_completion_proof.dart';
import '../../domain/value_objects/digital_signature.dart';
import '../../domain/value_objects/document_protection.dart';
import '../../domain/value_objects/location_capture.dart';
import '../../domain/value_objects/work_order.dart';
import '../../domain/value_objects/work_order_status.dart';

/// Filtros rápidos do painel de visitas (UC-03.02, UC-03.04).
enum WorkOrderListFilter {
  all,
  today,
  scheduled,
  inProgress,
  paused,
  completed,
}

final class WorkOrderListController extends IKortexController {
  WorkOrderListController({
    required this.repository,
    required this.locationService,
    required this.checklistProofPort,
    required this.getSettings,
    this.documentAtRestProtectionAvailable = kDocumentAtRestProtectionAvailable,
  });
  final IWorkOrderRepositoryPort repository;
  final ILocationServicePort locationService;
  final IChecklistProofPort checklistProofPort;

  /// Fonte única das políticas locais (UC-07.03/SEC-01).
  final GetSettings getSettings;

  /// Capacidade de proteção em repouso; injetável apenas para testes (SEC-04).
  final bool documentAtRestProtectionAvailable;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<List<WorkOrder>> items = KortexSignal<List<WorkOrder>>([]);
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  final KortexSignal<WorkOrderListFilter> filter =
      KortexSignal<WorkOrderListFilter>(WorkOrderListFilter.all);
  final KortexSignal<String?> startingId = KortexSignal<String?>(null);
  final KortexSignal<String?> completingId = KortexSignal<String?>(null);
  bool _loaded = false;

  /// Itens filtrados pelo chip selecionado.
  List<WorkOrder> get filteredItems {
    final selected = filter.value;
    final all = items.value;
    if (selected == WorkOrderListFilter.all) return all;
    final now = DateTime.now();
    return all.where((wo) {
      return switch (selected) {
        WorkOrderListFilter.all => true,
        WorkOrderListFilter.today => _isSameLocalDay(wo.scheduledAt, now),
        WorkOrderListFilter.scheduled => wo.status == WorkOrderStatus.scheduled,
        WorkOrderListFilter.inProgress =>
          wo.status == WorkOrderStatus.inProgress,
        WorkOrderListFilter.paused => wo.status == WorkOrderStatus.paused,
        WorkOrderListFilter.completed => wo.status == WorkOrderStatus.completed,
      };
    }).toList();
  }

  bool _isSameLocalDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final result = await repository.findAll();
    loading.value = false;
    switch (result) {
      case Success<List<WorkOrder>, ValidationError>(:final value):
        items.value = value;
      case Failure<List<WorkOrder>, ValidationError>(:final value):
        error.value = value.message;
    }
  }

  /// Lê a política vigente para a UI decidir exibição/coleta (SEC-02/SEC-04).
  Future<IResult<SettingsSnapshot, ValidationError>> loadPolicy() =>
      getSettings.execute();

  /// Inicia atendimento com captura de GPS (INV-SEC-19: fail-closed).
  Future<IResult<WorkOrder, ValidationError>> startService(
    String workOrderId,
  ) async {
    if (startingId.value != null) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.busy,
          message: 'Já existe um check-in em andamento.',
        ),
      );
    }
    startingId.value = workOrderId;
    final loc = await locationService.getCurrentLocation();
    final result = await _applyStart(workOrderId, switch (loc) {
      Success(:final value) => LocationCaptured(value),
      Failure(:final value) => _BypassOrFailure.failure(value),
    });
    startingId.value = null;
    return result;
  }

  /// Inicia atendimento com bypass tipado explícito (INV-SEC-17).
  Future<IResult<WorkOrder, ValidationError>> startServiceWithBypass(
    String workOrderId,
    CheckInBypassReason reason,
  ) async {
    if (startingId.value != null) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.busy,
          message: 'Já existe um check-in em andamento.',
        ),
      );
    }
    startingId.value = workOrderId;
    final result = await _applyStart(
      workOrderId,
      LocationBypassed(reason: reason),
    );
    startingId.value = null;
    return result;
  }

  /// Pausa OS com justificativa obrigatória (UC-03.04).
  Future<IResult<WorkOrder, ValidationError>> pause(
    String workOrderId,
    String reason,
  ) async {
    final wo = items.value.where((e) => e.id == workOrderId).firstOrNull;
    if (wo == null) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.notFound,
          message: 'OS não encontrada.',
        ),
      );
    }
    final paused = wo.pause(reason);
    switch (paused) {
      case Failure<WorkOrder, ValidationError>(:final value):
        return Failure(value);
      case Success<WorkOrder, ValidationError>(:final value):
        final saved = await repository.save(value);
        if (saved case Success<WorkOrder, ValidationError>(:final value)) {
          items.value = items.value
              .map((e) => e.id == workOrderId ? value : e)
              .toList();
        }
        return saved;
    }
  }

  /// Retoma OS pausada sem GPS (UC-03.04).
  Future<IResult<WorkOrder, ValidationError>> resume(String workOrderId) async {
    final wo = items.value.where((e) => e.id == workOrderId).firstOrNull;
    if (wo == null) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.notFound,
          message: 'OS não encontrada.',
        ),
      );
    }
    final resumed = wo.resume();
    switch (resumed) {
      case Failure<WorkOrder, ValidationError>(:final value):
        return Failure(value);
      case Success<WorkOrder, ValidationError>(:final value):
        final saved = await repository.save(value);
        if (saved case Success<WorkOrder, ValidationError>(:final value)) {
          items.value = items.value
              .map((e) => e.id == workOrderId ? value : e)
              .toList();
        }
        return saved;
    }
  }

  /// Cancela OS com justificativa obrigatória (UC-03.04).
  Future<IResult<WorkOrder, ValidationError>> cancel(
    String workOrderId,
    String reason,
  ) async {
    final wo = items.value.where((e) => e.id == workOrderId).firstOrNull;
    if (wo == null) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.notFound,
          message: 'OS não encontrada.',
        ),
      );
    }
    final cancelled = wo.cancel(reason);
    switch (cancelled) {
      case Failure<WorkOrder, ValidationError>(:final value):
        return Failure(value);
      case Success<WorkOrder, ValidationError>(:final value):
        final saved = await repository.save(value);
        if (saved case Success<WorkOrder, ValidationError>(:final value)) {
          items.value = items.value
              .map((e) => e.id == workOrderId ? value : e)
              .toList();
        }
        return saved;
    }
  }

  /// Conclui OS com check-out, assinatura e prova de checklist (UC-03.05, UC-04.07).
  Future<IResult<WorkOrder, ValidationError>> completeWorkOrder(
    String workOrderId, {
    required DigitalSignature signature,
  }) async {
    if (completingId.value != null) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.busy,
          message: 'Já existe uma conclusão em andamento.',
        ),
      );
    }
    completingId.value = workOrderId;
    try {
      final wo = items.value.where((e) => e.id == workOrderId).firstOrNull;
      if (wo == null) {
        return const Failure(
          ValidationError(
            code: WorkOrderFailureCodes.notFound,
            message: 'OS não encontrada.',
          ),
        );
      }
      final policyResult = await getSettings.execute();
      final SettingsSnapshot policy;
      switch (policyResult) {
        case Success(:final value):
          policy = value;
        case Failure(:final value):
          return Failure(value);
      }
      final policyError = _policyError(policy, signature);
      if (policyError != null) return Failure(policyError);
      final proofResult = await checklistProofPort.getProof(
        workOrderId: workOrderId,
        templateId: wo.checklistTemplateId,
        requireTemplate: policy.requireChecklistTemplate,
      );
      final ChecklistCompletionProof effectiveProof;
      switch (proofResult) {
        case Success(:final value):
          effectiveProof = value;
        case Failure(:final value):
          return Failure(value);
      }
      final loc = await locationService.getCurrentLocation();
      switch (loc) {
        case Failure(:final value):
          return Failure(value);
        case Success(:final value):
          final completed = wo.complete(
            signature: signature,
            checkOut: value,
            checklistProof: effectiveProof,
          );
          switch (completed) {
            case Failure<WorkOrder, ValidationError>(:final value):
              return Failure(value);
            case Success<WorkOrder, ValidationError>(:final value):
              final saved = await repository.save(value);
              if (saved case Success<WorkOrder, ValidationError>(
                :final value,
              )) {
                items.value = items.value
                    .map((e) => e.id == workOrderId ? value : e)
                    .toList();
              }
              return saved;
          }
      }
    } finally {
      completingId.value = null;
    }
  }

  ValidationError? _policyError(
    SettingsSnapshot policy,
    DigitalSignature signature,
  ) {
    if (policy.requireReceiverDocument && !documentAtRestProtectionAvailable) {
      return const ValidationError(
        code: WorkOrderFailureCodes.signatureDocumentProtectionUnavailable,
        message: kDocumentProtectionUnavailableMessage,
      );
    }
    if (policy.requireReceiverDocument && signature.documentNumber == null) {
      return const ValidationError(
        code: EvidenceFailureCodes.missingSignerDocument,
        message: 'Informe o documento do recebedor.',
      );
    }
    return null;
  }

  Future<IResult<WorkOrder, ValidationError>> _applyStart(
    String workOrderId,
    Object captureOrFailure,
  ) async {
    if (captureOrFailure is _BypassOrFailure) {
      return Failure(captureOrFailure.error);
    }
    final capture = captureOrFailure as LocationCapture;
    final wo = items.value.where((e) => e.id == workOrderId).firstOrNull;
    if (wo == null) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.notFound,
          message: 'OS não encontrada.',
        ),
      );
    }
    final started = wo.startService(capture);
    switch (started) {
      case Failure<WorkOrder, ValidationError>(:final value):
        return Failure(value);
      case Success<WorkOrder, ValidationError>(:final value):
        final saved = await repository.save(value);
        if (saved case Success<WorkOrder, ValidationError>(:final value)) {
          items.value = items.value
              .map((e) => e.id == workOrderId ? value : e)
              .toList();
        }
        return saved;
    }
  }

  @override
  void onDispose() {
    loading.dispose();
    items.dispose();
    error.dispose();
    filter.dispose();
    startingId.dispose();
    completingId.dispose();
  }
}

class _BypassOrFailure {
  const _BypassOrFailure.failure(this.error);
  final ValidationError error;
}
