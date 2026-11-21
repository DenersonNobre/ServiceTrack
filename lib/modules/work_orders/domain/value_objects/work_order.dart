// Agregado Ordem de Serviço (UC-03.01, UC-03.03, UC-03.04).
//
// SRP: validar e manter estado consistente da OS. Não persiste, não formata UI.
//
// Pattern: Entity/Value Object com Result.Fail tipado.

import 'package:dnolib/core/models/money.dart';
import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import 'check_in_record.dart';
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

  static IResult<WorkOrder, ValidationError> tryCreate({
    required String id,
    required String customerId,
    required String serviceDescription,
    required DateTime scheduledAt,
    required Money estimatedValue,
  }) {
    if (id.trim().isEmpty || customerId.trim().isEmpty) {
      return const Failure(
        ValidationError(code: 'ERR_OS_ID_INVALIDO', message: 'Identificador inválido.'),
      );
    }
    final desc = serviceDescription.trim();
    if (desc.isEmpty) {
      return const Failure(
        ValidationError(code: 'ERR_OS_DESCRICAO_INVALIDA', message: 'Informe a descrição do serviço.'),
      );
    }
    if (estimatedValue.currencyCode != 'BRL' || estimatedValue.scale != 2) {
      return const Failure(
        ValidationError(code: 'ERR_OS_VALOR_INVALIDO', message: 'Valor estimado inválido.'),
      );
    }
    if (estimatedValue.minorUnits.isNegative) {
      return const Failure(
        ValidationError(code: 'ERR_OS_VALOR_INVALIDO', message: 'Valor estimado não pode ser negativo.'),
      );
    }
    return Success(WorkOrder._(
      id: id.trim(),
      customerId: customerId.trim(),
      serviceDescription: desc,
      scheduledAt: scheduledAt.toUtc(),
      estimatedValue: estimatedValue,
      status: WorkOrderStatus.scheduled,
      checkIn: null,
      cancellationReason: null,
    ));
  }

  /// Inicia atendimento com evidência de localização tipada (INV-01/02, INV-SEC-17/19).
  IResult<WorkOrder, ValidationError> startService(LocationCapture capture) {
    if (status != WorkOrderStatus.scheduled) {
      return const Failure(
        ValidationError(
          code: 'ERR_OS_TRANSICAO_INVALIDA',
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
    ));
  }

  /// Cancela OS com justificativa obrigatória (UC-03.04).
  IResult<WorkOrder, ValidationError> cancel(String reason) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        ValidationError(
          code: 'ERR_OS_JUSTIFICATIVA_OBRIGATORIA',
          message: 'Informe a justificativa do cancelamento.',
        ),
      );
    }
    if (status == WorkOrderStatus.completed || status == WorkOrderStatus.cancelled) {
      return const Failure(
        ValidationError(
          code: 'ERR_OS_TRANSICAO_INVALIDA',
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
    );
  }

  @override
  String toString() => 'WorkOrder(redacted)';
}
