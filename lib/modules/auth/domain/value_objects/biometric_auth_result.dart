// Resultado tipado da autenticação biométrica (UC-01.02, INV-SEC-09).
//
// SRP: representar o desfecho da biometria como enum de domínio, sem vazar
// detalhes da plataforma. Não faz I/O nem mapeia plugins.
//
// Pattern: Value Object (enum tipado) para decisão fail-closed.

/// Desfecho da tentativa de autenticação biométrica.
enum BiometricAuthResult {
  /// Biometria confirmada pelo SO.
  success,

  /// Biometria lida, mas não reconhecida.
  failure,

  /// Usuário cancelou o prompt.
  canceled,

  /// Hardware indisponível, não enrolado ou sem suporte.
  unavailable,

  /// Bloqueio temporário pelo SO (muitas tentativas).
  lockoutTemporary,

  /// Bloqueio permanente pelo SO até credencial alternativa.
  lockoutPermanent,

  /// Erro de plataforma não classificado.
  error,
}
