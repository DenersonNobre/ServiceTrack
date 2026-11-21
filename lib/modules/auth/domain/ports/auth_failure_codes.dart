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
}
