/// Chaves de configuração canônicas da aplicação.
///
/// Centraliza os identificadores de persistência de configurações
/// para garantir compatibilidade e tipagem forte.
abstract final class SettingsKeys {
  /// Exige template de checklist na conclusão da OS (boolean).
  static const requireChecklistTemplate = 'require_checklist_template';

  /// Exige documento do recebedor na assinatura (boolean).
  static const requireReceiverDocument = 'require_receiver_document';

  /// Hora de início da jornada na agenda (formato 'HH:mm', default '08:00').
  static const scheduleDayStart = 'schedule_day_start';

  /// Hora de término da jornada na agenda (formato 'HH:mm', default '18:00').
  static const scheduleDayEnd = 'schedule_day_end';

  /// Intervalo dos slots de tempo em minutos (ex: '30', default '30').
  static const scheduleSlotInterval = 'schedule_slot_interval';
}
