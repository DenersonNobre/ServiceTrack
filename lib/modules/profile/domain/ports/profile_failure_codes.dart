// Códigos de falha do módulo de perfil comercial (UC-01.05 / UC-06.01).
//
// SRP: concentra os códigos ERR_PERFIL_* de validação e persistência.
// NÃO valida, NÃO persiste, NÃO toca em UI.
// Pattern: constantes nominais (elimina strings mágicas).
//
// Dependências: nenhuma.

/// Códigos de falha do domínio e repositório de perfil comercial.
abstract final class ProfileFailureCodes {
  /// Falha ao ler o arquivo de perfil comercial.
  static const readFailed = 'ERR_PERFIL_LEITURA';

  /// Falha ao gravar o arquivo de perfil comercial ou logo.
  static const writeFailed = 'ERR_PERFIL_ESCRITA';

  /// Imagem de logo inválida, vazia ou corrompida.
  static const invalidImage = 'ERR_PERFIL_IMAGEM_INVALIDA';

  /// Nome comercial vazio ou acima do limite permitido.
  static const invalidName = 'ERR_PERFIL_NOME_INVALIDO';

  /// Número de WhatsApp fora do formato brasileiro com DDD.
  static const invalidWhatsapp = 'ERR_PERFIL_WHATSAPP_INVALIDO';
}
