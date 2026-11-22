// Códigos de falha da autenticação local (UC-01.01).
//
// SRP: concentra os códigos ERR_* do cofre e da verificação.
// NÃO valida, NÃO persiste, NÃO toca em UI.
// Pattern: constantes nominais (elimina strings mágicas).
//
// Dependências: nenhuma.

/// Códigos de falha do repositório de credenciais.
abstract final class AuthFailureCodes {
  /// PIN incorreto com tentativas restantes.
  static const pinAttemptsLeft = 'ERR_PIN_INCORRETO_TENTATIVAS_RESTANTES';

  /// PIN bloqueado temporariamente após esgotar tentativas.
  static const pinLockedOut = 'ERR_PIN_BLOQUEADO_TEMPORARIAMENTE';

  /// Senha mestre incorreta na verificação/recuperação.
  static const wrongPassword = 'ERR_SENHA_INCORRETA';

  /// Senha mestre bloqueada temporariamente por rate-limit (UC-01.04/A1).
  static const passwordLockedOut = 'ERR_SENHA_BLOQUEADA_TEMPORARIAMENTE';

  /// Nenhuma credencial cadastrada no cofre.
  static const noCredentials = 'ERR_CREDENCIAIS_NAO_CADASTRADAS';

  /// Cofre indisponível (I/O da plataforma).
  static const storeUnavailable = 'ERR_COFRE_INDISPONIVEL';

  /// E-mail de contato inválido no onboarding.
  static const invalidEmail = 'ERR_EMAIL_INVALIDO';

  /// Senha mestre abaixo do comprimento mínimo (8 caracteres).
  static const passwordTooShort = 'ERR_SENHA_CURTA';

  /// PIN fora do formato numérico de 4 a 6 dígitos.
  static const invalidPin = 'ERR_PIN_INVALIDO';

  /// Nome do técnico obrigatório ausente ou muito curto.
  static const nameRequired = 'ERR_NOME_OBRIGATORIO';

  /// Tentativa de recuperação de PIN sem prova de autenticação válida.
  static const recoveryUnauthorized = 'ERR_RECUPERACAO_NAO_AUTORIZADA';
}
