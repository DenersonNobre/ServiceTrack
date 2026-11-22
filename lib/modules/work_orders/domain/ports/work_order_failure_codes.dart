// Códigos de falha do módulo de Ordens de Serviço (UC-03.01..UC-03.05 / UC-06.01).
//
// SRP: concentra os códigos ERR_OS_*, ERR_LOCALIZACAO_*, ERR_GEO_*,
// ERR_CHECKLIST_INCOMPLETO e ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL.
// NÃO valida, NÃO persiste, NÃO toca em UI.
// Pattern: constantes nominais (elimina strings mágicas).
//
// Dependências: nenhuma.

/// Códigos de falha do domínio, repositórios e serviços de Ordens de Serviço.
abstract final class WorkOrderFailureCodes {
  /// Serviço de localização (GPS) desligado no aparelho.
  static const locationServiceDisabled = 'ERR_LOCALIZACAO_SERVICO_DESLIGADO';

  /// Permissão de localização negada.
  static const locationPermissionDenied = 'ERR_LOCALIZACAO_PERMISSAO_NEGADA';

  /// Permissão de localização negada permanentemente.
  static const locationPermissionDeniedForever =
      'ERR_LOCALIZACAO_PERMISSAO_NEGADA_PERMANENTE';

  /// Dados de localização inválidos retornados pelo sensor.
  static const locationInvalidData = 'ERR_LOCALIZACAO_DADOS_INVALIDOS';

  /// Tempo esgotado ao capturar GPS.
  static const locationTimeout = 'ERR_LOCALIZACAO_TIMEOUT';

  /// Localização indisponível no momento.
  static const locationUnavailable = 'ERR_LOCALIZACAO_INDISPONIVEL';

  /// Proteção em repouso indisponível para documento do assinante (UC-04.08/C-01).
  static const signatureDocumentProtectionUnavailable =
      'ERR_ASSINATURA_DOCUMENTO_PROTECAO_INDISPONIVEL';

  /// Tentativa de alterar OS concluída/imutável (INV-06 / INV-SEC-23).
  static const immutable = 'ERR_OS_IMUTAVEL';

  /// Falha de persistência SQLite de Ordem de Serviço.
  static const persistence = 'ERR_OS_PERSISTENCIA';

  /// Dados corrompidos ou inválidos ao reidratar OS do banco.
  static const invalidData = 'ERR_OS_DADOS_INVALIDOS';

  /// Checklist obrigatório incompleto para conclusão da OS (INV-03).
  static const checklistIncomplete = 'ERR_CHECKLIST_INCOMPLETO';

  /// Coordenadas geográficas inválidas.
  static const invalidGeoData = 'ERR_GEO_DADOS_INVALIDOS';

  /// Identificador de OS inválido.
  static const invalidId = 'ERR_OS_ID_INVALIDO';

  /// Descrição do serviço vazia ou inválida.
  static const invalidDescription = 'ERR_OS_DESCRICAO_INVALIDA';

  /// Valor estimado inválido ou negativo.
  static const invalidAmount = 'ERR_OS_VALOR_INVALIDO';

  /// Transição de estado inválida na máquina de estados da OS.
  static const invalidTransition = 'ERR_OS_TRANSICAO_INVALIDA';

  /// Justificativa obrigatória ausente ao pausar ou cancelar OS.
  static const justificationRequired = 'ERR_OS_JUSTIFICATIVA_OBRIGATORIA';

  /// Operação concorrente em andamento na mesma OS.
  static const busy = 'ERR_OS_OCUPADO';

  /// Ordem de Serviço não encontrada.
  static const notFound = 'ERR_OS_NAO_ENCONTRADA';
}
