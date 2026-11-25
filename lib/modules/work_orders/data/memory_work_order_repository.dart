// Repositório em memória de OS (testes/fallback).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../../../core/security/document_at_rest_cipher_port.dart';
import '../domain/ports/work_order_failure_codes.dart';
import '../domain/ports/work_order_repository_port.dart';
import '../domain/value_objects/work_order.dart';

final class MemoryWorkOrderRepository implements IWorkOrderRepositoryPort {
  MemoryWorkOrderRepository({this.documentCipher});
  final IDocumentAtRestCipher? documentCipher;
  final Map<String, WorkOrder> _store = {};

  @override
  Future<IResult<WorkOrder, ValidationError>> save(WorkOrder workOrder) async {
    final doc = workOrder.signature?.documentNumber;
    if (doc != null) {
      final cipher = documentCipher;
      if (cipher == null) {
        return const Failure(
          ValidationError(
            code: WorkOrderFailureCodes.signatureDocumentProtectionUnavailable,
            message:
                'Documento do recebedor não pode ser persistido sem proteção em repouso (D-01/C-01).',
          ),
        );
      }
      final encrypted = await cipher.encrypt(doc);
      if (encrypted.isFailure) {
        return Failure(encrypted.getOrNullFailure()!);
      }
    }
    _store[workOrder.id] = workOrder;
    return Success(workOrder);
  }

  @override
  Future<IResult<List<WorkOrder>, ValidationError>> findAll() async {
    final list = _store.values.toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return Success(list);
  }
}
