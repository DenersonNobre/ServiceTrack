// Item de leitura para histórico visual de laudos (UC-05.04).
//
// SRP: transportar dados mínimos para listar OS concluídas elegíveis à reemissão.
// Não contém regra de negócio, I/O ou dependência de UI.

/// DTO imutável para exibição no histórico de laudos.
final class ReportHistoryItem {
  const ReportHistoryItem({
    required this.workOrderId,
    required this.serviceDescription,
    required this.scheduledDateFormatted,
    this.completedDateFormatted,
    this.customerName,
    required this.status,
  });

  final String workOrderId;
  final String serviceDescription;
  final String scheduledDateFormatted;
  final String? completedDateFormatted;
  final String? customerName;
  final String status;
}
