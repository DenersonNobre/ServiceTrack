import '../value_objects/.index.dart';

/// Snapshot imutável das configurações locais.
///
/// SRP: expor valores tipados com defaults seguros para chaves ausentes.
/// Não persiste nem renderiza.
final class SettingsSnapshot {
  /// Cria o snapshot preenchendo defaults para chaves não informadas.
  SettingsSnapshot([Map<SettingKey, Object> values = const {}])
    : _values = Map.unmodifiable({
        for (final key in SettingKey.values)
          key: values[key] ?? key.defaultValue,
      });

  /// Snapshot com todos os defaults do catálogo.
  factory SettingsSnapshot.defaults() => SettingsSnapshot();

  final Map<SettingKey, Object> _values;

  /// Valor genérico da chave (default quando ausente).
  Object rawValueFor(SettingKey key) => _values[key] ?? key.defaultValue;

  /// Valor booleano tipado da chave (default quando ausente).
  bool boolValueFor(SettingKey key) {
    final val = rawValueFor(key);
    if (val is bool) return val;
    if (val is String) return val.toLowerCase() == 'true';
    return key.defaultValue as bool;
  }

  /// Valor string tipado da chave (default quando ausente).
  String stringValueFor(SettingKey key) {
    final val = rawValueFor(key);
    return val.toString();
  }

  /// Valor int tipado da chave (default quando ausente).
  int intValueFor(SettingKey key) {
    final val = rawValueFor(key);
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? (key.defaultValue as int);
    return key.defaultValue as int;
  }

  /// Exige template de checklist na conclusão.
  bool get requireChecklistTemplate =>
      boolValueFor(SettingKey.requireChecklistTemplate);

  /// Exige documento do recebedor na assinatura.
  bool get requireReceiverDocument =>
      boolValueFor(SettingKey.requireReceiverDocument);

  /// Hora de início da jornada na agenda (ex: '08:00').
  String get scheduleDayStart =>
      stringValueFor(SettingKey.scheduleDayStart);

  /// Hora de fim da jornada na agenda (ex: '18:00').
  String get scheduleDayEnd =>
      stringValueFor(SettingKey.scheduleDayEnd);

  /// Intervalo dos slots de tempo em minutos (ex: 30).
  int get scheduleSlotInterval =>
      intValueFor(SettingKey.scheduleSlotInterval);

  /// Retorna novo snapshot com uma chave atualizada.
  SettingsSnapshot withValue(SettingKey key, Object value) =>
      SettingsSnapshot({..._values, key: value});

  @override
  bool operator ==(Object other) {
    if (other is! SettingsSnapshot) return false;
    for (final key in SettingKey.values) {
      if (other.rawValueFor(key) != rawValueFor(key)) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([for (final key in SettingKey.values) rawValueFor(key)]);
}

