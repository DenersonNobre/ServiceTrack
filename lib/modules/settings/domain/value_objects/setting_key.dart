import '../settings_keys.dart';

/// Catálogo tipado de configurações locais.
///
/// SRP: mapear chave persistida ↔ política tipada e seu default seguro.
/// Não acessa storage nem UI.
enum SettingKey {
  /// Exige template de checklist na conclusão da OS (D-05/política C).
  requireChecklistTemplate(SettingsKeys.requireChecklistTemplate, true),

  /// Exige documento do recebedor na assinatura (D2/ADR-001; minimização).
  requireReceiverDocument(SettingsKeys.requireReceiverDocument, false),

  /// Hora de início da jornada na agenda (default '08:00').
  scheduleDayStart(SettingsKeys.scheduleDayStart, '08:00'),

  /// Hora de fim da jornada na agenda (default '18:00').
  scheduleDayEnd(SettingsKeys.scheduleDayEnd, '18:00'),

  /// Intervalo dos slots em minutos (default 30).
  scheduleSlotInterval(SettingsKeys.scheduleSlotInterval, 30);

  const SettingKey(this.storageKey, this.defaultValue);

  /// Chave estável persistida no SQLite.
  final String storageKey;

  /// Valor padrão seguro.
  final Object defaultValue;

  /// Resolve a chave persistida para o catálogo; `null` se desconhecida.
  static SettingKey? fromStorageKey(String key) {
    for (final value in values) {
      if (value.storageKey == key) return value;
    }
    return null;
  }
}

