// Controller do formulário de OS (UC-03.01).
//
// SRP: orquestrar criação de OS. Não renderiza UI.

import 'package:kortex_lib/core/models/money.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';
import 'package:uuid/uuid.dart';

import '../../../checklists/domain/entities/checklist_template.dart';
import '../../../checklists/domain/ports/checklist_template_repository_port.dart';
import '../../../customers/domain/ports/customer_repository_port.dart';
import '../../../customers/domain/value_objects/customer.dart';
import '../../domain/ports/work_order_repository_port.dart';
import '../../domain/value_objects/work_order.dart';

final class WorkOrderFormController extends IKortexController {
  WorkOrderFormController({
    required this.repository,
    required this.customerRepository,
    this.checklistTemplateRepository,
  });
  final IWorkOrderRepositoryPort repository;
  final ICustomerRepositoryPort customerRepository;
  final IChecklistTemplateRepositoryPort? checklistTemplateRepository;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<bool> saving = KortexSignal<bool>(false);
  final KortexSignal<List<Customer>> customers = KortexSignal<List<Customer>>([]);
  final KortexSignal<List<ChecklistTemplate>> templates =
      KortexSignal<List<ChecklistTemplate>>([]);
  final KortexSignal<String?> customerId = KortexSignal<String?>(null);
  final KortexSignal<String?> checklistTemplateId = KortexSignal<String?>(null);
  final KortexSignal<String> description = KortexSignal<String>('');
  final KortexSignal<DateTime> scheduledAt = KortexSignal<DateTime>(DateTime.now().toUtc());
  final KortexSignal<String> scheduledDate = KortexSignal<String>(
    _formatDate(DateTime.now()),
  );
  final KortexSignal<String> scheduledTime = KortexSignal<String>('08:00');
  final KortexSignal<String> estimatedValue = KortexSignal<String>('');
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  final KortexSignal<bool> saved = KortexSignal<bool>(false);
  bool _loaded = false;

  static String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  /// Lista de horários permitidos de 30 em 30 min das 08:00 às 18:00.
  static const List<String> availableTimeSlots = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
  ];

  /// Atualiza a data agendada (formato DD/MM/AAAA) e recalcula [scheduledAt].
  void updateScheduledDate(String dateText) {
    scheduledDate.value = dateText;
    _recalculateScheduledAt();
  }

  /// Atualiza o horário agendado (formato HH:mm) e recalcula [scheduledAt].
  void updateScheduledTime(String timeText) {
    scheduledTime.value = timeText;
    _recalculateScheduledAt();
  }

  void _recalculateScheduledAt() {
    final parts = scheduledDate.value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      final timeParts = scheduledTime.value.split(':');
      final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 8 : 8;
      final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

      if (day != null && month != null && year != null) {
        try {
          scheduledAt.value = DateTime.utc(year, month, day, hour, minute);
        } catch (_) {}
      }
    }
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final result = await customerRepository.findAll();
    final tplRepo = checklistTemplateRepository;
    if (tplRepo != null) {
      final tplResult = await tplRepo.findAll();
      if (tplResult case Success<List<ChecklistTemplate>, ValidationError>(:final value)) {
        templates.value = value;
      }
    }
    loading.value = false;
    if (result case Success<List<Customer>, ValidationError>(:final value)) {
      customers.value = value;
      if (value.isNotEmpty) customerId.value = value.first.id;
    } else if (result case Failure<List<Customer>, ValidationError>(:final value)) {
      error.value = value.message;
    }
  }

  Future<void> save() async {
    if (saving.value) return;
    saving.value = true;
    error.value = null;
    final cid = customerId.value;
    if (cid == null || cid.isEmpty) {
      saving.value = false;
      error.value = 'Selecione um cliente.';
      return;
    }
    final moneyR = Money.tryParse(
      estimatedValue.value.isEmpty ? '0' : estimatedValue.value,
      currencyCode: 'BRL',
      scale: 2,
      decimalSeparator: ',',
      groupSeparator: '.',
    );
    if (moneyR.isFailure) {
      saving.value = false;
      error.value = 'Valor estimado inválido.';
      return;
    }
    final woR = WorkOrder.tryCreate(
      id: const Uuid().v4(),
      customerId: cid,
      serviceDescription: description.value,
      scheduledAt: scheduledAt.value,
      estimatedValue: moneyR.value!,
      checklistTemplateId: checklistTemplateId.value,
    );
    switch (woR) {
      case Failure<WorkOrder, ValidationError>(:final value):
        saving.value = false;
        error.value = value.message;
        return;
      case Success<WorkOrder, ValidationError>(:final value):
        final savedR = await repository.save(value);
        saving.value = false;
        switch (savedR) {
          case Success<WorkOrder, ValidationError>():
            saved.value = true;
          case Failure<WorkOrder, ValidationError>(:final value):
            error.value = value.message;
        }
    }
  }

  @override
  void onDispose() {
    loading.dispose();
    saving.dispose();
    customers.dispose();
    templates.dispose();
    customerId.dispose();
    checklistTemplateId.dispose();
    description.dispose();
    scheduledAt.dispose();
    scheduledDate.dispose();
    scheduledTime.dispose();
    estimatedValue.dispose();
    error.dispose();
    saved.dispose();
  }
}
