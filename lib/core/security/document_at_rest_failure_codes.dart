// Códigos de falha do módulo de segurança em repouso (D-01/C-01).
//
// SRP: concentrar códigos ERR_* de proteção de documentos em repouso.
// NÃO cifra, NÃO persiste, NÃO toca em UI.

/// Códigos de falha da proteção em repouso de documentos sensíveis.
abstract final class DocumentAtRestFailureCodes {
  /// Cifrador/armazenamento seguro indisponível ou payload inválido.
  static const protectionUnavailable = 'ERR_DOCUMENTO_PROTECAO_INDISPONIVEL';

  /// Cofre seguro do SO (Keystore/Keychain) indisponível ou com falha de hardware/I/O.
  static const vaultUnavailable = 'ERR_VAULT_UNAVAILABLE';
}
