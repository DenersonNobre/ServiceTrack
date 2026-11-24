// Porta do repositório/armazenamento local de laudos PDF (UC-05.04).
//
// SRP: Definir o contrato para persistir, verificar e recuperar laudos salvos localmente.
// Não implementa I/O de disco nem conhece detalhes de UI.

import 'dart:typed_data';

import 'package:kortex_lib/kortex_lib.dart';

/// Contrato para armazenamento local de laudos em PDF de Ordens de Serviço.
abstract interface class IReportStoragePort {
  /// Recupera os bytes do laudo previamente salvo para a OS especificada.
  Future<IResult<Uint8List, ValidationError>> getSavedReport(String workOrderId);

  /// Salva os bytes do laudo compilado no armazenamento local da aplicação.
  /// Retorna o caminho absoluto do arquivo salvo em caso de sucesso.
  Future<IResult<String, ValidationError>> saveReport({
    required String workOrderId,
    required Uint8List bytes,
  });

  /// Verifica se já existe um laudo salvo localmente para a OS especificada.
  Future<bool> hasSavedReport(String workOrderId);
}
