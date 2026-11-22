// Status da Ordem de Serviço (INV-01/INV-06).
//
// SRP: representar os estados canônicos da OS. Não contém transição.

/// Estados canônicos da Ordem de Serviço.
enum WorkOrderStatus {
  scheduled,
  inProgress,
  paused,
  completed,
  cancelled;

  /// Nome canônico para persistência.
  String get code => switch (this) {
        WorkOrderStatus.scheduled => 'SCHEDULED',
        WorkOrderStatus.inProgress => 'IN_PROGRESS',
        WorkOrderStatus.paused => 'PAUSED',
        WorkOrderStatus.completed => 'COMPLETED',
        WorkOrderStatus.cancelled => 'CANCELLED',
      };

  static WorkOrderStatus? fromCode(String code) => switch (code) {
        'SCHEDULED' => WorkOrderStatus.scheduled,
        'IN_PROGRESS' => WorkOrderStatus.inProgress,
        'PAUSED' => WorkOrderStatus.paused,
        'COMPLETED' => WorkOrderStatus.completed,
        'CANCELLED' => WorkOrderStatus.cancelled,
        _ => null,
      };
}
