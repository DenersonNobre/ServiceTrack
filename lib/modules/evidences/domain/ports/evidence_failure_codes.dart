// Códigos de falha do módulo de evidências e assinatura (UC-04.03 / UC-04.04 / UC-06.01).
//
// SRP: concentra os códigos ERR_IMAGEM_*, ERR_EVIDENCIA_*, ERR_GEO_* e ERR_ASSINAT*.
// NÃO valida, NÃO persiste, NÃO toca em UI.
// Pattern: constantes nominais (elimina strings mágicas).
//
// Dependências: nenhuma.

/// Códigos de falha do domínio e adaptadores de evidências fotográficas e assinatura.
abstract final class EvidenceFailureCodes {
  /// Bytes de imagem vazios na compressão.
  static const emptyImage = 'ERR_IMAGEM_VAZIA';

  /// Bytes de imagem não decodificáveis ou formato inválido.
  static const invalidImage = 'ERR_IMAGEM_INVALIDA';

  /// Falha ao comprimir/codificar a imagem.
  static const imageCompressionFailed = 'ERR_IMAGEM_COMPRESSAO';

  /// Tamanho da evidência fotográfica fora do limite permitido (<= 400KB).
  static const invalidEvidenceSize = 'ERR_EVIDENCIA_TAMANHO_INVALIDO';

  /// Cota máxima de fotos por OS excedida (INV-04).
  static const evidenceLimitExceeded = 'ERR_EVIDENCIA_LIMITE_EXCEDIDO';

  /// Metadados obrigatórios da evidência inválidos.
  static const invalidEvidenceData = 'ERR_EVIDENCIA_DADOS_INVALIDOS';

  /// Coordenadas geográficas ausentes ou fora de faixa válida.
  static const invalidGeo = 'ERR_GEO_INVALIDO_OU_AUSENTE';

  /// Assinatura PNG ausente ou vazia.
  static const missingSignature = 'ERR_ASSINATURA_AUSENTE';

  /// Assinatura PNG excede o limite máximo permitido (150KB).
  static const signatureSizeExceeded = 'ERR_ASSINATURA_TAMANHO_EXCEDIDO';

  /// Bytes de assinatura não correspondem a um PNG válido.
  static const invalidSignature = 'ERR_ASSINATURA_INVALIDA';

  /// Nome do recebedor/assinante obrigatório ausente.
  static const missingSignerName = 'ERR_ASSINANTE_NOME_OBRIGATORIO';

  /// Documento do recebedor obrigatório pela política local ausente.
  static const missingSignerDocument = 'ERR_ASSINANTE_DOCUMENTO_OBRIGATORIO';

  /// Documento do recebedor fora do formato permitido.
  static const invalidSignerDocument = 'ERR_ASSINANTE_DOCUMENTO_INVALIDO';
}
