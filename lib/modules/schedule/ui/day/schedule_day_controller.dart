// Controller Kortex da visão diária da agenda (UC-03.01, UC-05.02).
//
// SRP: gerenciar estado da agenda diária, timeline de horários e filtragem de OS do dia.
// Não renderiza UI, não persiste, não navega.

import 'package:intl/intl.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/core/patterns/result.dart';

import '../../../settings/domain/entities/settings_snapshot.dart';
import '../../../settings/features/get_settings.dart';
import '../../../work_orders/domain/ports/work_order_repository_port.dart';
import '../../../work_orders/domain/value_objects/work_order.dart';

/// Controller reativo da agenda diária do técnico com timeline vertical.
final class ScheduleDayController extends IKortexController {
  /// Construtor recebendo repositório e caso de uso de settings.
  ScheduleDayController({
    required this.repository,
    required this.getSettings,
    DateTime? initialDate,
  }) {
    final now = initialDate ?? DateTime.now();
    selectedDate = KortexSignal<DateTime>(now);
    dayWorkOrders = KortexSignal<List<WorkOrder>>(<WorkOrder>[]);
    timeSlots = KortexSignal<List<String>>(<String>[]);
    loading = KortexSignal<bool>(false);
    error = KortexSignal<String?>(null);
  }

  /// Repositório de persistência de Ordens de Serviço.
  final IWorkOrderRepositoryPort repository;

  /// Caso de uso para obter configurações de jornada.
  final GetSettings getSettings;

  /// Data atualmente em exibição na agenda diária.
  late final KortexSignal<DateTime> selectedDate;

  /// Lista de OS agendadas para o dia selecionado.
  late final KortexSignal<List<WorkOrder>> dayWorkOrders;

  /// Lista de slots de horários calculados para o dia (ex: ['08:00', '08:30', ...]).
  late final KortexSignal<List<String>> timeSlots;

  /// Indicador de carregamento em progresso.
  late final KortexSignal<bool> loading;

  /// Mensagem de erro em caso de falha.
  late final KortexSignal<String?> error;

  List<WorkOrder> _allWorkOrders = [];
  SettingsSnapshot _settings = SettingsSnapshot.defaults();
  bool _loaded = false;
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  /// Garante que os dados sejam carregados na abertura da tela.
  void ensureLoaded() {
    if (_isDisposed || _loaded) return;
    _loaded = true;
    // ignore: discarded_futures
    load();
  }

  /// Avança 1 dia na agenda.
  void nextDay() {
    final current = selectedDate.value;
    selectedDate.value = current.add(const Duration(days: 1));
    _filterDayWorkOrders();
  }

  /// Recua 1 dia na agenda.
  void previousDay() {
    final current = selectedDate.value;
    selectedDate.value = current.subtract(const Duration(days: 1));
    _filterDayWorkOrders();
  }

  /// Seleciona uma data específica.
  void setDate(DateTime date) {
    selectedDate.value = date;
    _filterDayWorkOrders();
  }

  /// Retorna para a data atual (hoje).
  void jumpToToday() {
    selectedDate.value = DateTime.now();
    _filterDayWorkOrders();
  }

  /// Gera a lista de strings de horários com base nas configurações.
  List<String> _generateTimeSlots(String start, String end, int intervalMinutes) {
    final slots = <String>[];
    try {
      final startParts = start.split(':');
      final endParts = end.split(':');

      final startHour = int.parse(startParts[0]);
      final startMin = startParts.length > 1 ? int.parse(startParts[1]) : 0;

      final endHour = int.parse(endParts[0]);
      final endMin = endParts.length > 1 ? int.parse(endParts[1]) : 0;

      var currentMinutes = startHour * 60 + startMin;
      final endMinutes = endHour * 60 + endMin;
      final step = intervalMinutes > 0 ? intervalMinutes : 30;

      while (currentMinutes <= endMinutes) {
        final h = (currentMinutes ~/ 60).toString().padLeft(2, '0');
        final m = (currentMinutes % 60).toString().padLeft(2, '0');
        slots.add('$h:$m');
        currentMinutes += step;
      }
    } catch (_) {
      // Fallback seguro em caso de string malformada
      for (var h = 8; h <= 18; h++) {
        slots.add('${h.toString().padLeft(2, '0')}:00');
        if (h < 18) slots.add('${h.toString().padLeft(2, '0')}:30');
      }
    }
    return slots;
  }

  /// Filtra as ordens de serviço correspondentes à data selecionada.
  void _filterDayWorkOrders() {
    final target = selectedDate.value;
    dayWorkOrders.value = _allWorkOrders.where((wo) {
      final local = wo.scheduledAt.toLocal();
      return local.year == target.year &&
          local.month == target.month &&
          local.day == target.day;
    }).toList();
  }

  /// Retorna a lista de ordens agendadas para um horário específico (formato 'HH:mm').
  List<WorkOrder> workOrdersForSlot(String timeSlot) {
    return dayWorkOrders.value.where((wo) {
      final formatted = DateFormat('HH:mm').format(wo.scheduledAt.toLocal());
      return formatted == timeSlot;
    }).toList();
  }

  /// Carrega as configurações e todas as ordens de serviço.
  Future<void> load() async {
    if (_isDisposed) return;
    loading.value = true;
    error.value = null;

    final settingsRes = await getSettings.execute();
    if (settingsRes case Success(:final value)) {
      _settings = value;
    }

    timeSlots.value = _generateTimeSlots(
      _settings.scheduleDayStart,
      _settings.scheduleDayEnd,
      _settings.scheduleSlotInterval,
    );

    final result = await repository.findAll();
    if (_isDisposed) return;

    result.fold(
      onSuccess: (items) {
        _allWorkOrders = items;
        _filterDayWorkOrders();
        loading.value = false;
      },
      onFailure: (failure) {
        error.value = failure.message;
        loading.value = false;
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    selectedDate.dispose();
    dayWorkOrders.dispose();
    timeSlots.dispose();
    loading.dispose();
    error.dispose();
    super.dispose();
  }
}
