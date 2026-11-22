/// Códigos de falha do módulo de configurações locais.
abstract final class SettingsFailureCodes {
  /// Chave fora do catálogo tipado.
  static const invalidKey = 'ERR_CONFIGURACAO_CHAVE_INVALIDA';

  /// Valor persistido incompatível com o tipo da chave.
  static const invalidValue = 'ERR_CONFIGURACAO_VALOR_INVALIDO';

  /// Falha de leitura/escrita no SQLite.
  static const persistence = 'ERR_CONFIGURACAO_PERSISTENCIA';
}
