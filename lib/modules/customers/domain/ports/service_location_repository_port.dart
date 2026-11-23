// Porta de repositório de locais de atendimento (UC-02.02).
//
// SRP: contrato de persistência de locais por cliente. Não conhece SQLite/UI.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../value_objects/service_location.dart';

/// Contrato de persistência de locais de atendimento.
abstract interface class IServiceLocationRepositoryPort {
  Future<IResult<ServiceLocation, ValidationError>> save(ServiceLocation location);
  Future<IResult<List<ServiceLocation>, ValidationError>> findByCustomerId(String customerId);
  Future<IResult<bool, ValidationError>> delete(String id);
}
