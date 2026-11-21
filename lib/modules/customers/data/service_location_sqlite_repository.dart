// Repositório SQLite de locais de atendimento (UC-02.02).
//
// SRP: persistir e carregar locais em SQLite. Não contém UI.
//
// Pattern: Adapter (Port impl) + Result.Fail.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:dnolib/sqlite/sqlite.dart';

import '../domain/ports/service_location_repository_port.dart';
import '../domain/value_objects/service_location.dart';
import 'service_location_migration.dart';

/// Repositório SQLite de locais de atendimento.
final class ServiceLocationSqliteRepository implements IServiceLocationRepositoryPort {
  ServiceLocationSqliteRepository({required this.provider});
  final SqliteProvider provider;

  @override
  Future<IResult<ServiceLocation, ValidationError>> save(ServiceLocation location) async {
    try {
      final db = await provider.db;
      final now = DateTime.now().toUtc().toIso8601String();
      final data = {
        'id': location.id,
        'customer_id': location.customerId,
        'label': location.label.value,
        'street': location.street,
        'number': location.number,
        'neighborhood': location.neighborhood,
        'city': location.city,
        'state': location.state,
        'cep': location.cep?.digits,
        'reference': location.reference,
        'updated_at': now,
      };
      final existing = await db.query(
        ServiceLocationMigration.table,
        where: 'id = ?',
        whereArgs: [location.id],
        limit: 1,
      );
      if (existing.isEmpty) {
        data['created_at'] = now;
        await db.insert(ServiceLocationMigration.table, data);
      } else {
        await db.update(ServiceLocationMigration.table, data, where: 'id = ?', whereArgs: [location.id]);
      }
      return Success(location);
    } catch (_) {
      return const Failure(
        ValidationError(code: 'ERR_LOCAL_PERSISTENCIA', message: 'Não foi possível salvar o local.'),
      );
    }
  }

  @override
  Future<IResult<List<ServiceLocation>, ValidationError>> findByCustomerId(String customerId) async {
    try {
      final db = await provider.db;
      final rows = await db.query(
        ServiceLocationMigration.table,
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'label COLLATE NOCASE ASC',
      );
      final locations = <ServiceLocation>[];
      for (final row in rows) {
        final mapped = _mapRow(row);
        if (mapped.isFailure) return Failure(mapped.getOrNullFailure()!);
        locations.add(mapped.getOrNull()!);
      }
      return Success(locations);
    } catch (_) {
      return const Failure(
        ValidationError(code: 'ERR_LOCAL_PERSISTENCIA', message: 'Não foi possível carregar os locais.'),
      );
    }
  }

  @override
  Future<IResult<bool, ValidationError>> delete(String id) async {
    try {
      final db = await provider.db;
      await db.delete(ServiceLocationMigration.table, where: 'id = ?', whereArgs: [id]);
      return const Success(true);
    } catch (_) {
      return const Failure(
        ValidationError(code: 'ERR_LOCAL_PERSISTENCIA', message: 'Não foi possível remover o local.'),
      );
    }
  }

  IResult<ServiceLocation, ValidationError> _mapRow(Map<String, Object?> row) {
    return ServiceLocation.tryCreate(
      id: (row['id'] ?? '') as String,
      customerId: (row['customer_id'] ?? '') as String,
      label: (row['label'] ?? '') as String,
      street: (row['street'] ?? '') as String,
      number: (row['number'] ?? '') as String,
      neighborhood: (row['neighborhood'] ?? '') as String,
      city: (row['city'] ?? '') as String,
      state: (row['state'] ?? '') as String,
      cep: (row['cep'] ?? '') as String,
      reference: (row['reference'] ?? '') as String,
    );
  }
}
