import '../value_objects/.index.dart';

/// Snapshot imutável das configurações locais.
///
/// SRP: expor valores tipados com defaults seguros para chaves ausentes.
/// Não persiste nem renderiza.
final class SettingsSnapshot {
  /// Cria o snapshot preenchendo defaults para chaves não informadas.
  SettingsSnapshot([Map<SettingKey, bool> values = const {}])
    : _values = Map.unmodifiable({
        for (final key in SettingKey.values)
          key: values[key] ?? key.defaultValue,
      });

  /// Snapshot com todos os defaults do catálogo.
  factory SettingsSnapshot.defaults() => SettingsSnapshot();

  final Map<SettingKey, bool> _values;

  /// Valor tipado da chave (default quando ausente).
  bool valueFor(SettingKey key) => _values[key] ?? key.defaultValue;

  /// Exige template de checklist na conclusão.
  bool get requireChecklistTemplate =>
      valueFor(SettingKey.requireChecklistTemplate);

  /// Exige documento do recebedor na assinatura.
  bool get requireReceiverDocument =>
      valueFor(SettingKey.requireReceiverDocument);

  /// Retorna novo snapshot com uma chave atualizada.
  SettingsSnapshot withValue(SettingKey key, bool value) =>
      SettingsSnapshot({..._values, key: value});

  @override
  bool operator ==(Object other) {
    if (other is! SettingsSnapshot) return false;
    for (final key in SettingKey.values) {
      if (other.valueFor(key) != valueFor(key)) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([for (final key in SettingKey.values) valueFor(key)]);
}
