// Agregado Ordem de Serviço (UC-03.01, UC-03.03, UC-03.04, UC-03.05).
//
// SRP: validar e manter estado consistente da OS. Não persiste, não formata UI.
//
// Pattern: Entity/Value Object com Result.Fail tipado.

import 'package:dnolib/core/models/money.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../ports/work_order_failure_codes.dart';
import 'check_in_record.dart';
import 'checklist_completion_proof.dart';
import 'digital_signature.dart';
import 'geo_point.dart';
import 'location_capture.dart';
import 'work_order_status.dart';

/// Agregado raiz Ordem de Serviço.
final class WorkOrder {
  const WorkOrder._({
    required this.id,
    required this.customerId,
    required this.serviceDescription,
    required this.scheduledAt,
    required this.estimatedValue,
    required this.status,
    required this.checkIn,
    required this.cancellationReason,
    required this.pauseReason,
    required this.checkOut,
    required this.signature,
    required this.checklistProof,
    required this.checklistTemplateId,
  });

  final String id;
  final String customerId;
  final String serviceDescription;
  final DateTime scheduledAt;
  final Money estimatedValue;
  final WorkOrderStatus status;

  /// Evidência de check-in (INV-02, INV-SEC-17).
  final CheckInRecord? checkIn;

  /// Justificativa de cancelamento (UC-03.04).
  final String? cancellationReason;

  /// Justificativa de pausa (UC-03.04).
  final String? pauseReason;

  /// Check-out georreferenciado (UC-03.05, INV-SEC-24).
  final GeoPoint? checkOut;

  /// Assinatura do recebedor (UC-03.05, INV-SEC-24).
  final DigitalSignature? signature;

  /// Prova de checklist obrigatório completo (UC-03.05, INV-SEC-22).
  final ChecklistCompletionProof? checklistProof;

  /// Template de checklist vinculado à OS (UC-04.06/07).
  final String? checklistTemplateId;

  static IResult<WorkOrder, ValidationError> tryCreate({
    required String id,
    required String customerId,
    required String serviceDescription,
    required DateTime scheduledAt,
    required Money estimatedValue,
    String? checklistTemplateId,
  }) {
    if (id.trim().isEmpty || customerId.trim().isEmpty) {
      return const Failure(
        ValidationError(code: WorkOrderFailureCodes.invalidId, message: 'Identificador inválido.'),
      );
    }
    final desc = serviceDescription.trim();
    if (desc.isEmpty) {
      return const Failure(
        ValidationError(code: WorkOrderFailureCodes.invalidDescription, message: 'Informe a descrição do serviço.'),
      );
    }
    if (estimatedValue.currencyCode != 'BRL' || estimatedValue.scale != 2) {
      return const Failure(
        ValidationError(code: WorkOrderFailureCodes.invalidAmount, message: 'Valor estimado inválido.'),
      );
    }
    if (estimatedValue.minorUnits.isNegative) {
      return const Failure(
        ValidationError(code: WorkOrderFailureCodes.invalidAmount, message: 'Valor estimado não pode ser negativo.'),
      );
    }
    final tpl = checklistTemplateId?.trim();
    final normalizedTemplateId = (tpl == null || tpl.isEmpty) ? null : tpl;
    return Success(WorkOrder._(
      id: id.trim(),
      customerId: customerId.trim(),
      serviceDescription: desc,
      scheduledAt: scheduledAt.toUtc(),
      estimatedValue: estimatedValue,
      status: WorkOrderStatus.scheduled,
      checkIn: null,
      cancellationReason: null,
      pauseReason: null,
      checkOut: null,
      signature: null,
      checklistProof: null,
      checklistTemplateId: normalizedTemplateId,
    ));
  }

  /// Inicia atendimento com evidência de localização tipada (INV-01/02, INV-SEC-17/19).
  IResult<WorkOrder, ValidationError> startService(LocationCapture capture) {
    if (status == WorkOrderStatus.completed) {
      return const Failure(
        ValidationError(code: WorkOrderFailureCodes.invalidTransition, message: 'Transição de estado inválida para a OS.'),
      );
    }
    if (status != WorkOrderStatus.scheduled) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.invalidTransition,
          message: 'Transição de estado inválida para a OS.',
        ),
      );
    }
    final record = switch (capture) {
      LocationCaptured(:final point) => CheckInGps(point),
      LocationBypassed(:final reason) => CheckInBypassed(
          reason: reason,
          timestampUtc: DateTime.now().toUtc(),
        ),
    };
    return Success(WorkOrder._(
      id: id,
      customerId: customerId,
      serviceDescription: serviceDescription,
      scheduledAt: scheduledAt,
      estimatedValue: estimatedValue,
      status: WorkOrderStatus.inProgress,
      checkIn: record,
      cancellationReason: null,
      pauseReason: null,
      checkOut: null,
      signature: null,
      checklistProof: null,
      checklistTemplateId: checklistTemplateId,
    ));
  }

  /// Pausa OS com justificativa obrigatória (UC-03.04).
  IResult<WorkOrder, ValidationError> pause(String reason) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.justificationRequired,
          message: 'Informe a justificativa da pausa.',
        ),
      );
    }
    if (status != WorkOrderStatus.inProgress) {
      return const Failure(
        ValidationError(code: WorkOrderFailureCodes.invalidTransition, message: 'Transição de estado inválida para a OS.'),
      );
    }
    return Success(WorkOrder._(
      id: id,
      customerId: customerId,
      serviceDescription: serviceDescription,
      scheduledAt: scheduledAt,
      estimatedValue: estimatedValue,
      status: WorkOrderStatus.paused,
      checkIn: checkIn,
      cancellationReason: null,
      pauseReason: trimmed,
      checkOut: checkOut,
      signature: signature,
      checklistProof: checklistProof,
      checklistTemplateId: checklistTemplateId,
    ));
  }

  /// Retoma OS pausada sem GPS (UC-03.04).
  IResult<WorkOrder, ValidationError> resume() {
    if (status != WorkOrderStatus.paused) {
      return const Failure(
        ValidationError(code: WorkOrderFailureCodes.invalidTransition, message: 'Transição de estado inválida para a OS.'),
      );
    }
    return Success(WorkOrder._(
      id: id,
      customerId: customerId,
      serviceDescription: serviceDescription,
      scheduledAt: scheduledAt,
      estimatedValue: estimatedValue,
      status: WorkOrderStatus.inProgress,
      checkIn: checkIn,
      cancellationReason: null,
      pauseReason: null,
      checkOut: checkOut,
      signature: signature,
      checklistProof: checklistProof,
      checklistTemplateId: checklistTemplateId,
    ));
  }

  /// Cancela OS com justificativa obrigatória (UC-03.04).
  IResult<WorkOrder, ValidationError> cancel(String reason) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.justificationRequired,
          message: 'Informe a justificativa do cancelamento.',
        ),
      );
    }
    if (status == WorkOrderStatus.completed || status == WorkOrderStatus.cancelled) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.invalidTransition,
          message: 'Transição de estado inválida para a OS.',
        ),
      );
    }
    return Success(WorkOrder._(
      id: id,
      customerId: customerId,
      serviceDescription: serviceDescription,
      scheduledAt: scheduledAt,
      estimatedValue: estimatedValue,
      status: WorkOrderStatus.cancelled,
      checkIn: checkIn,
      cancellationReason: trimmed,
      pauseReason: pauseReason,
      checkOut: checkOut,
      signature: signature,
      checklistProof: checklistProof,
      checklistTemplateId: checklistTemplateId,
    ));
  }

  /// Conclui OS com evidências obrigatórias (UC-03.05, INV-01/03/06, INV-SEC-22/23).
  IResult<WorkOrder, ValidationError> complete({
    required DigitalSignature signature,
    required GeoPoint checkOut,
    required ChecklistCompletionProof checklistProof,
  }) {
    if (status != WorkOrderStatus.inProgress) {
      return const Failure(
        ValidationError(
          code: WorkOrderFailureCodes.invalidTransition,
          message: 'Transição de estado inválida para a OS.',
        ),
      );
    }
    return Success(WorkOrder._(
      id: id,
      customerId: customerId,
      serviceDescription: serviceDescription,
      scheduledAt: scheduledAt,
      estimatedValue: estimatedValue,
      status: WorkOrderStatus.completed,
      checkIn: checkIn,
      cancellationReason: null,
      pauseReason: pauseReason,
      checkOut: checkOut,
      signature: signature,
      checklistProof: checklistProof,
      checklistTemplateId: checklistTemplateId,
    ));
  }

  /// Reidratação de persistência (confia em dados já validados).
  static WorkOrder restore({
    required String id,
    required String customerId,
    required String serviceDescription,
    required DateTime scheduledAt,
    required Money estimatedValue,
    required WorkOrderStatus status,
    CheckInRecord? checkIn,
    String? cancellationReason,
    String? pauseReason,
    GeoPoint? checkOut,
    DigitalSignature? signature,
    ChecklistCompletionProof? checklistProof,
    String? checklistTemplateId,
  }) {
    return WorkOrder._(
      id: id,
      customerId: customerId,
      serviceDescription: serviceDescription,
      scheduledAt: scheduledAt,
      estimatedValue: estimatedValue,
      status: status,
      checkIn: checkIn,
      cancellationReason: cancellationReason,
      pauseReason: pauseReason,
      checkOut: checkOut,
      signature: signature,
      checklistProof: checklistProof,
      checklistTemplateId: checklistTemplateId,
    );
  }

  @override
  String toString() => 'WorkOrder(redacted)';
}
