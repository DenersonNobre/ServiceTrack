// Repositório SQLite de Ordens de Serviço (UC-03.01).
//
// SRP: persistir e carregar OS em SQLite. Não contém UI.

import 'package:dnolib/core/models/money.dart';
import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:dnolib/sqlite/sqlite.dart';

import '../domain/ports/work_order_repository_port.dart';
import '../domain/value_objects/work_order.dart';
import '../domain/value_objects/work_order_status.dart';
import 'work_order_migration.dart';

/// Repositório SQLite de Ordens de Serviço.
final class WorkOrderSqliteRepository implements IWorkOrderRepositoryPort {
  WorkOrderSqliteRepository({required this.provider});
  final SqliteProvider provider;

  @override
  Future<IResult<WorkOrder, ValidationError>> save(WorkOrder workOrder) async {
    try {
      final db = await provider.db;
      final now = DateTime.now().toUtc().toIso8601String();
      final data = {
        'id': workOrder.id,
        'customer_id': workOrder.customerId,
        'service_description': workOrder.serviceDescription,
        'scheduled_at': workOrder.scheduledAt.toUtc().toIso8601String(),
        'estimated_value_minor': workOrder.estimatedValue.minorUnits.toInt(),
        'estimated_value_currency': workOrder.estimatedValue.currencyCode,
        'estimated_value_scale': workOrder.estimatedValue.scale,
        'status': workOrder.status.code,
        'updated_at': now,
      };
      final existing = await db.query(WorkOrderMigration.table, where: 'id = ?', whereArgs: [workOrder.id], limit: 1);
      if (existing.isEmpty) {
        data['created_at'] = now;
        await db.insert(WorkOrderMigration.table, data);
        return Success(workOrder);
      }
      await db.update(WorkOrderMigration.table, data, where: 'id = ?', whereArgs: [workOrder.id]);
      return Success(workOrder);
    } catch (_) {
      return const Failure(
        ValidationError(code: 'ERR_OS_PERSISTENCIA', message: 'Não foi possível salvar a OS.'),
      );
    }
  }

  @override
  Future<IResult<List<WorkOrder>, ValidationError>> findAll() async {
    try {
      final db = await provider.db;
      final rows = await db.query(WorkOrderMigration.table, orderBy: 'scheduled_at DESC');
      final items = <WorkOrder>[];
      for (final row in rows) {
        final mapped = _mapRow(row);
        if (mapped.isFailure) return Failure(mapped.getOrNullFailure()!);
        items.add(mapped.getOrNull()!);
      }
      return Success(items);
    } catch (_) {
      return const Failure(
        ValidationError(code: 'ERR_OS_PERSISTENCIA', message: 'Não foi possível carregar as OS.'),
      );
    }
  }

  IResult<WorkOrder, ValidationError> _mapRow(Map<String, Object?> row) {
    final statusCode = (row['status'] ?? '') as String;
    final status = WorkOrderStatus.fromCode(statusCode);
    if (status == null) {
      return const Failure(ValidationError(code: 'ERR_OS_DADOS_INVALIDOS', message: 'Dados de OS inválidos.'));
    }
    final minor = row['estimated_value_minor'];
    final minorInt = minor is int ? minor : int.tryParse('$minor') ?? 0;
    final scale = row['estimated_value_scale'] as int? ?? 2;
    final currency = (row['estimated_value_currency'] ?? 'BRL') as String;
    final scheduledRaw = (row['scheduled_at'] ?? '') as String;
    final scheduledAt = DateTime.tryParse(scheduledRaw)?.toUtc() ?? DateTime.now().toUtc();
    final money = Money.fromMinorUnits(minorInt, currencyCode: currency, scale: scale);
    // Reconstruct with tryCreate-like validation bypass for persisted trusted shape; use internal fields by recreating via tryCreate and then checking status.
    final created = WorkOrder.tryCreate(
      id: (row['id'] ?? '') as String,
      customerId: (row['customer_id'] ?? '') as String,
      serviceDescription: (row['service_description'] ?? '') as String,
      scheduledAt: scheduledAt,
      estimatedValue: money,
    );
    return switch (created) {
      Success<WorkOrder, ValidationError>(:final value) => Success(_withStatus(value, status)),
      Failure<WorkOrder, ValidationError>(:final value) => Failure(value),
    };
  }

  WorkOrder _withStatus(WorkOrder wo, WorkOrderStatus status) {
    // WorkOrder is immutable; for persisted rows we trust status. Use a simple reconstruction via tryCreate gives scheduled; for now only scheduled is created in UC-03.01. For future statuses, we'll need a factory.
    if (status == WorkOrderStatus.scheduled) return wo;
    return WorkOrder.restore(
      id: wo.id,
      customerId: wo.customerId,
      serviceDescription: wo.serviceDescription,
      scheduledAt: wo.scheduledAt,
      estimatedValue: wo.estimatedValue,
      status: status,
    );
  }
}
