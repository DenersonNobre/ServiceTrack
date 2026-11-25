// Controller Kortex do módulo de Agenda e Calendário Interativo (UC-03.01, UC-05.02).
//
// SRP: gerenciar estado do calendário mensal bidimensional, seleção de datas
// e filtragem de Ordens de Serviço por dia. Não renderiza UI, não persiste, não navega.

import 'package:kortex/kortex.dart';

import '../../work_orders/domain/ports/work_order_repository_port.dart';
import '../../work_orders/domain/value_objects/work_order.dart';

/// Controller reativo da agenda do técnico.
final class ScheduleController extends IKortexController {
  /// Cria o controller da agenda injetando o repositório de Ordens de Serviço.
  ScheduleController({
    required this.repository,
    DateTime? initialDate,
  }) {
    final now = initialDate ?? DateTime.now();
    currentMonth = KortexSignal<DateTime>(DateTime(now.year, now.month));
    selectedDate = KortexSignal<DateTime?>(now);
    workOrders = KortexSignal<List<WorkOrder>>(<WorkOrder>[]);
    loading = KortexSignal<bool>(false);
    error = KortexSignal<String?>(null);
  }

  /// Repositório de persistência de Ordens de Serviço.
  final IWorkOrderRepositoryPort repository;

  /// Mês e ano de referência exibidos no calendário (dia fixado em 1).
  late final KortexSignal<DateTime> currentMonth;

  /// Data selecionada pelo usuário no grid do mês.
  late final KortexSignal<DateTime?> selectedDate;

  /// Todas as Ordens de Serviço carregadas para a agenda.
  late final KortexSignal<List<WorkOrder>> workOrders;

  /// Indicador de carregamento em segundo plano.
  late final KortexSignal<bool> loading;

  /// Mensagem de erro em caso de falha de carregamento.
  late final KortexSignal<String?> error;

  bool _loaded = false;
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  /// Garante que os dados sejam carregados na inicialização da página.
  void ensureLoaded() {
    if (_isDisposed || _loaded) return;
    _loaded = true;
    // ignore: discarded_futures
    load();
  }

  /// Avança o calendário em 1 mês.
  void nextMonth() {
    final current = currentMonth.value;
    final next = DateTime(current.year, current.month + 1);
    currentMonth.value = next;
  }

  /// Recua o calendário em 1 mês.
  void previousMonth() {
    final current = currentMonth.value;
    final prev = DateTime(current.year, current.month - 1);
    currentMonth.value = prev;
  }

  /// Avança o calendário em 1 ano mantendo o mesmo mês.
  void nextYear() {
    final current = currentMonth.value;
    final next = DateTime(current.year + 1, current.month);
    currentMonth.value = next;
  }

  /// Recua o calendário em 1 ano mantendo o mesmo mês.
  void previousYear() {
    final current = currentMonth.value;
    final prev = DateTime(current.year - 1, current.month);
    currentMonth.value = prev;
  }

  /// Seleciona uma data específica no calendário.
  void selectDate(DateTime date) {
    selectedDate.value = date;
  }

  /// Retorna imediatamente para a data e mês atuais.
  void jumpToToday() {
    final now = DateTime.now();
    currentMonth.value = DateTime(now.year, now.month);
    selectedDate.value = now;
  }

  /// Filtra as Ordens de Serviço agendadas para o dia especificado (em fuso local).
  List<WorkOrder> workOrdersForDate(DateTime date) {
    return workOrders.value.where((wo) {
      final local = wo.scheduledAt.toLocal();
      return local.year == date.year &&
          local.month == date.month &&
          local.day == date.day;
    }).toList();
  }

  /// Ordens de Serviço do dia selecionado atualmente.
  List<WorkOrder> get selectedDateWorkOrders {
    final selected = selectedDate.value;
    if (selected == null) return const <WorkOrder>[];
    return workOrdersForDate(selected);
  }

  /// Contagem de atendimentos agendados em uma data específica.
  int countForDate(DateTime date) {
    return workOrdersForDate(date).length;
  }

  /// Carrega as Ordens de Serviço cadastradas.
  Future<void> load() async {
    if (_isDisposed) return;
    loading.value = true;
    error.value = null;

    final result = await repository.findAll();
    if (_isDisposed) return;

    result.fold(
      onSuccess: (items) {
        workOrders.value = items;
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
    currentMonth.dispose();
    selectedDate.dispose();
    workOrders.dispose();
    loading.dispose();
    error.dispose();
    super.dispose();
  }
}
