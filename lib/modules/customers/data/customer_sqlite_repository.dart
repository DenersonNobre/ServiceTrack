// Repositório SQLite de clientes (UC-02.01).
//
// SRP: persistir e carregar clientes em SQLite. Não contém UI.
//
// Pattern: Adapter (Port impl) + Result.Fail.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:dnolib/sqlite/sqlite.dart';

import '../domain/ports/customer_failure_codes.dart';
import '../domain/ports/customer_repository_port.dart';
import '../domain/value_objects/customer.dart';
import 'customer_migration.dart';

/// Repositório SQLite de clientes.
final class CustomerSqliteRepository implements ICustomerRepositoryPort {
  CustomerSqliteRepository({required this.provider});
  final SqliteProvider provider;

  @override
  Future<IResult<Customer, ValidationError>> save(Customer customer) async {
    try {
      final db = await provider.db;
      final now = DateTime.now().toUtc().toIso8601String();
      final data = {
        'id': customer.id,
        'name': customer.name.value,
        'document': customer.document?.digits,
        'whatsapp': customer.whatsapp.digits,
        'email': customer.email?.value,
        'notes': customer.notes,
        'updated_at': now,
      };
      final existing = await db.query(
        CustomerMigration.table,
        where: 'id = ?',
        whereArgs: [customer.id],
        limit: 1,
      );
      if (existing.isEmpty) {
        data['created_at'] = now;
        await db.insert(CustomerMigration.table, data);
      } else {
        await db.update(CustomerMigration.table, data, where: 'id = ?', whereArgs: [customer.id]);
      }
      return Success(customer);
    } catch (_) {
      return const Failure(
        ValidationError(code: CustomerFailureCodes.customerPersistence, message: 'Não foi possível salvar o cliente.'),
      );
    }
  }

  @override
  Future<IResult<Customer?, ValidationError>> findById(String id) async {
    try {
      final db = await provider.db;
      final rows = await db.query(CustomerMigration.table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return const Success(null);
      return _mapRow(rows.first);
    } catch (_) {
      return const Failure(
        ValidationError(code: CustomerFailureCodes.customerPersistence, message: 'Não foi possível carregar o cliente.'),
      );
    }
  }

  @override
  Future<IResult<List<Customer>, ValidationError>> findAll() async {
    try {
      final db = await provider.db;
      final rows = await db.query(CustomerMigration.table, orderBy: 'name COLLATE NOCASE ASC');
      final customers = <Customer>[];
      for (final row in rows) {
        final mapped = _mapRow(row);
        if (mapped.isFailure) return Failure(mapped.getOrNullFailure()!);
        customers.add(mapped.getOrNull()!);
      }
      return Success(customers);
    } catch (_) {
      return const Failure(
        ValidationError(code: CustomerFailureCodes.customerPersistence, message: 'Não foi possível carregar clientes.'),
      );
    }
  }

  IResult<Customer?, ValidationError> _mapRow(Map<String, Object?> row) {
    final result = Customer.tryCreate(
      id: (row['id'] ?? '') as String,
      name: (row['name'] ?? '') as String,
      document: (row['document'] ?? '') as String,
      whatsapp: (row['whatsapp'] ?? '') as String,
      email: (row['email'] ?? '') as String,
      notes: (row['notes'] ?? '') as String,
    );
    return switch (result) {
      Success<Customer, ValidationError>(:final value) => Success(value),
      Failure<Customer, ValidationError>(:final value) => Failure(value),
    };
  }
}
