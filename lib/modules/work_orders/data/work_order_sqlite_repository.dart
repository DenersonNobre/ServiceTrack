// Repositório SQLite de Ordens de Serviço (UC-03.01, UC-03.03).
//
// SRP: persistir e carregar OS em SQLite. Não contém UI.

import 'package:dnolib/core/models/money.dart';
import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:dnolib/sqlite/sqlite.dart';

import '../domain/ports/work_order_repository_port.dart';
import '../domain/value_objects/check_in_bypass_reason.dart';
import '../domain/value_objects/check_in_record.dart';
import '../domain/value_objects/geo_point.dart';
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
      final data = <String, Object?>{
        'id': workOrder.id,
        'customer_id': workOrder.customerId,
        'service_description': workOrder.serviceDescription,
        'scheduled_at': workOrder.scheduledAt.toUtc().toIso8601String(),
        'estimated_value_minor': workOrder.estimatedValue.minorUnits.toInt(),
        'estimated_value_currency': workOrder.estimatedValue.currencyCode,
        'estimated_value_scale': workOrder.estimatedValue.scale,
        'status': workOrder.status.code,
        'updated_at': now,
        'check_in_lat': null,
        'check_in_lng': null,
        'check_in_at': null,
        'check_in_source': null,
        'check_in_bypass_reason': null,
      };
      final checkIn = workOrder.checkIn;
      if (checkIn case CheckInGps(:final point)) {
        data['check_in_lat'] = point.latitude;
        data['check_in_lng'] = point.longitude;
        data['check_in_at'] = point.timestampUtc.toIso8601String();
        data['check_in_source'] = 'GPS';
      } else if (checkIn case CheckInBypassed(:final reason, :final timestampUtc)) {
        data['check_in_at'] = timestampUtc.toIso8601String();
        data['check_in_source'] = 'BYPASS';
        data['check_in_bypass_reason'] = reason.code;
      }
      final existing = await db.query(
        WorkOrderMigration.table,
        where: 'id = ?',
        whereArgs: [workOrder.id],
        limit: 1,
      );
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
    final created = WorkOrder.tryCreate(
      id: (row['id'] ?? '') as String,
      customerId: (row['customer_id'] ?? '') as String,
      serviceDescription: (row['service_description'] ?? '') as String,
      scheduledAt: scheduledAt,
      estimatedValue: money,
    );
    if (created case Failure<WorkOrder, ValidationError>(:final value)) return Failure(value);
    final base = created.getOrNull()!;
    final checkInR = _mapCheckIn(row);
    if (checkInR case Failure<CheckInRecord?, ValidationError>(:final value)) return Failure(value);
    return Success(
      WorkOrder.restore(
        id: base.id,
        customerId: base.customerId,
        serviceDescription: base.serviceDescription,
        scheduledAt: base.scheduledAt,
        estimatedValue: base.estimatedValue,
        status: status,
        checkIn: checkInR.getOrNull(),
      ),
    );
  }

  IResult<CheckInRecord?, ValidationError> _mapCheckIn(Map<String, Object?> row) {
    final source = row['check_in_source'] as String?;
    if (source == null || source.isEmpty) return const Success(null);
    final atRaw = row['check_in_at'] as String?;
    final at = DateTime.tryParse(atRaw ?? '')?.toUtc();
    if (at == null) {
      return const Failure(ValidationError(code: 'ERR_OS_DADOS_INVALIDOS', message: 'Dados de OS inválidos.'));
    }
    if (source == 'GPS') {
      final lat = _toDouble(row['check_in_lat']);
      final lng = _toDouble(row['check_in_lng']);
      if (lat == null || lng == null) {
        return const Failure(ValidationError(code: 'ERR_OS_DADOS_INVALIDOS', message: 'Dados de OS inválidos.'));
      }
      final gp = GeoPoint.tryCreate(latitude: lat, longitude: lng, timestampUtc: at);
      return switch (gp) {
        Success<GeoPoint, ValidationError>(:final value) => Success(CheckInGps(value)),
        Failure<GeoPoint, ValidationError>() => const Failure(
            ValidationError(code: 'ERR_OS_DADOS_INVALIDOS', message: 'Dados de OS inválidos.'),
          ),
      };
    }
    if (source == 'BYPASS') {
      final reason = CheckInBypassReason.fromCode((row['check_in_bypass_reason'] ?? '') as String);
      if (reason == null) {
        return const Failure(ValidationError(code: 'ERR_OS_DADOS_INVALIDOS', message: 'Dados de OS inválidos.'));
      }
      return Success(CheckInBypassed(reason: reason, timestampUtc: at));
    }
    return const Failure(ValidationError(code: 'ERR_OS_DADOS_INVALIDOS', message: 'Dados de OS inválidos.'));
  }

  double? _toDouble(Object? v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}
