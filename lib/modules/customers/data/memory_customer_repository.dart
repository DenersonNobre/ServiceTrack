// Repositório em memória de clientes (testes/fallback).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../domain/ports/customer_repository_port.dart';
import '../domain/value_objects/customer.dart';

final class MemoryCustomerRepository implements ICustomerRepositoryPort {
  final Map<String, Customer> _store = {};

  @override
  Future<IResult<Customer, ValidationError>> save(Customer customer) async {
    _store[customer.id] = customer;
    return Success(customer);
  }

  @override
  Future<IResult<Customer?, ValidationError>> findById(String id) async =>
      Success(_store[id]);

  @override
  Future<IResult<List<Customer>, ValidationError>> findAll() async {
    final list = _store.values.toList()
      ..sort((a, b) => a.name.value.toLowerCase().compareTo(b.name.value.toLowerCase()));
    return Success(list);
  }
}
