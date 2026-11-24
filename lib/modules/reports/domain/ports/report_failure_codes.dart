// Códigos de falha do módulo de relatórios e laudos PDF (UC-05.01 / UC-06.01).
//
// SRP: concentra os códigos nominais ERR_LAUDO_* e ERR_OS_* do motor de PDF.
// NÃO valida, NÃO persiste, NÃO toca em UI.
// Pattern: constantes nominais (elimina strings mágicas).

/// Códigos de falha do motor de laudos técnicos e compartilhamento.
abstract final class ReportFailureCodes {
  /// Tentativa de gerar laudo de OS que não está com status COMPLETED.
  static const workOrderNotCompleted = 'ERR_OS_NAO_CONCLUIDA';

  /// Falha na compilação ou renderização binária do PDF em Isolate.run.
  static const pdfGenerationFailed = 'ERR_LAUDO_GERACAO_FALHOU';

  /// Nome de arquivo inválido ou vazio para o laudo.
  static const invalidReportFileName = 'ERR_LAUDO_ARQUIVO_INVALIDO';

  /// Ordem de serviço não encontrada no repositório.
  static const workOrderNotFound = 'ERR_OS_NAO_ENCONTRADA';
}
