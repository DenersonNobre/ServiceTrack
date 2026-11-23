// Porta de repositório de Ordens de Serviço (UC-03.01).
//
// SRP: contrato de persistência de OS. Não conhece SQLite/UI.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../value_objects/work_order.dart';

/// Contrato de persistência de Ordens de Serviço.
abstract interface class IWorkOrderRepositoryPort {
  Future<IResult<WorkOrder, ValidationError>> save(WorkOrder workOrder);
  Future<IResult<List<WorkOrder>, ValidationError>> findAll();
}
