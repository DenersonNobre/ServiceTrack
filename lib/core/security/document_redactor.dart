// Utilitário de mascaramento / redaction de documentos para LGPD e privacidade (UC-08.03, C-11).
//
// SRP: Redigir documentos (CPF, CNPJ, outros) ocultando dados sensíveis e mantendo apenas
// caracteres necessários para conferência, evitando vazamento de PII.

/// Utilitário puro de ofuscação/redaction de documentos cadastrais e de recebedores.
abstract final class DocumentRedactor {
  /// Redige um documento pessoal ou empresarial.
  ///
  /// - CPF (11 dígitos numéricos): formata como `***.456.789-**`
  /// - CNPJ (14 dígitos numéricos): formata como `**.345.678/0001-**`
  /// - Outros formatos/alfanuméricos:
  ///   - Se <= 4 caracteres: substitui todos por `*`.
  ///   - Se > 4 caracteres: oculta início e fim com `**`, mantendo parte central.
  /// - Nulo, vazio ou somente espaços: retorna `''`.
  static String redact(String? document) {
    if (document == null) return '';
    final trimmed = document.trim();
    if (trimmed.isEmpty) return '';

    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');

    // CPF: 11 dígitos
    if (digitsOnly.length == 11) {
      final part2 = digitsOnly.substring(3, 6);
      final part3 = digitsOnly.substring(6, 9);
      return '***.$part2.$part3-**';
    }

    // CNPJ: 14 dígitos
    if (digitsOnly.length == 14) {
      final part2 = digitsOnly.substring(2, 5);
      final part3 = digitsOnly.substring(5, 8);
      final part4 = digitsOnly.substring(8, 12);
      return '**.$part2.$part3/$part4-**';
    }

    // Alfanumérico genérico / RG / Outros
    if (trimmed.length <= 4) {
      return '*' * trimmed.length;
    }

    // Preserva centro, ofusca início e fim com asteriscos
    final prefixLength = (trimmed.length * 0.25).ceil().clamp(2, 4);
    final suffixLength = (trimmed.length * 0.25).ceil().clamp(2, 4);
    final middle = trimmed.substring(prefixLength, trimmed.length - suffixLength);

    final prefixStars = '*' * prefixLength;
    final suffixStars = '*' * suffixLength;
    return '$prefixStars$middle$suffixStars';
  }
}
