// Porta de repositório de clientes (UC-02.01).
//
// SRP: contrato de persistência de clientes. Não conhece SQLite/UI.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../value_objects/customer.dart';

/// Contrato de persistência de clientes.
abstract interface class ICustomerRepositoryPort {
  Future<IResult<Customer, ValidationError>> save(Customer customer);
  Future<IResult<Customer?, ValidationError>> findById(String id);
  Future<IResult<List<Customer>, ValidationError>> findAll();
}
