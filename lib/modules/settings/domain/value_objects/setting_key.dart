/// Catálogo tipado de configurações locais.
///
/// SRP: mapear chave persistida ↔ política tipada e seu default seguro.
/// Não acessa storage nem UI.
enum SettingKey {
  /// Exige template de checklist na conclusão da OS (D-05/política C).
  requireChecklistTemplate('require_checklist_template', true),

  /// Exige documento do recebedor na assinatura (D2/ADR-001; minimização).
  requireReceiverDocument('require_receiver_document', false);

  const SettingKey(this.storageKey, this.defaultValue);

  /// Chave estável persistida no SQLite.
  final String storageKey;

  /// Valor padrão seguro.
  final bool defaultValue;

  /// Resolve a chave persistida para o catálogo; `null` se desconhecida.
  static SettingKey? fromStorageKey(String key) {
    for (final value in values) {
      if (value.storageKey == key) return value;
    }
    return null;
  }
}
