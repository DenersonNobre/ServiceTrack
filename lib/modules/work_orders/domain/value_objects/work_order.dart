// Agregado Ordem de Serviço (UC-03.01, base EPIC-03).
//
// SRP: validar e manter estado consistente da OS. Não persiste, não formata UI.
//
// Pattern: Entity/Value Object com Result.Fail tipado.

import 'package:dnolib/core/models/money.dart';
import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

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
  });

  final String id;
  final String customerId;
  final String serviceDescription;
  final DateTime scheduledAt;
  final Money estimatedValue;
  final WorkOrderStatus status;

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
  }) {
    return WorkOrder._(
      id: id,
      customerId: customerId,
      serviceDescription: serviceDescription,
      scheduledAt: scheduledAt,
      estimatedValue: estimatedValue,
      status: status,
    );
  }

  @override
  String toString() => 'WorkOrder(redacted)';
}
