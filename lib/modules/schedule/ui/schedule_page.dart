// Tela do módulo de Agenda e Calendário Interativo 2D (UC-03.01, UC-05.02).
//
// SRP: renderizar calendário mensal com gestos bidimensionais (Horizontal: Mês, Vertical: Ano)
// e lista de Ordens de Serviço do dia selecionado.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kortex/kortex.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/ui/app_status_badge.dart';
import '../../../core/ui/app_touch_target.dart';
import '../../work_orders/domain/value_objects/work_order.dart';
import '../../work_orders/domain/value_objects/work_order_status.dart';
import 'schedule_controller.dart';

/// Página principal da agenda interativa.
final class SchedulePage extends IKortexPage<ScheduleController> {
  const SchedulePage({
    super.key,
    this.onWorkOrderTapped,
  });

  /// Callback ao clicar em uma Ordem de Serviço na listagem do dia.
  final void Function(String workOrderId)? onWorkOrderTapped;

  static const _monthNamesPtBr = <int, String>{
    1: 'Janeiro',
    2: 'Fevereiro',
    3: 'Março',
    4: 'Abril',
    5: 'Maio',
    6: 'Junho',
    7: 'Julho',
    8: 'Agosto',
    9: 'Setembro',
    10: 'Outubro',
    11: 'Novembro',
    12: 'Dezembro',
  };

  static const _weekDayNames = <String>[
    'Dom',
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
  ];

  @override
  Widget buildPage(BuildContext context, ScheduleController controller) {
    controller.ensureLoaded();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Agenda'),
        actions: [
          TextButton.icon(
            key: const Key('schedule-today-button'),
            icon: const Icon(Icons.today_outlined, size: 20),
            label: const Text('Hoje'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryAction,
              minimumSize: const Size(48, 48),
            ),
            onPressed: controller.jumpToToday,
          ),
        ],
      ),
      body: KortexWatch(
        builder: (context, _) {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error.value != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.error.value!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.load,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildHeader(controller),
              _buildGestureCalendar(controller),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: _buildAppointmentsSection(controller),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ScheduleController controller) {
    final current = controller.currentMonth.value;
    final monthName = _monthNamesPtBr[current.month] ?? '';
    final year = current.year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Controle do Ano (< Ano >)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('schedule-prev-year'),
                icon: const Icon(Icons.keyboard_double_arrow_left),
                tooltip: 'Ano anterior',
                constraints: kMinTouchTargetConstraints,
                onPressed: controller.previousYear,
              ),
              IconButton(
                key: const Key('schedule-prev-month'),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Mês anterior',
                constraints: kMinTouchTargetConstraints,
                onPressed: controller.previousMonth,
              ),
            ],
          ),
          Text(
            '$monthName $year',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('schedule-next-month'),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Próximo mês',
                constraints: kMinTouchTargetConstraints,
                onPressed: controller.nextMonth,
              ),
              IconButton(
                key: const Key('schedule-next-year'),
                icon: const Icon(Icons.keyboard_double_arrow_right),
                tooltip: 'Próximo ano',
                constraints: kMinTouchTargetConstraints,
                onPressed: controller.nextYear,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGestureCalendar(ScheduleController controller) {
    double dragDx = 0.0;
    double dragDy = 0.0;

    return GestureDetector(
      key: const Key('schedule-gesture-detector'),
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        dragDx += details.delta.dx;
        dragDy += details.delta.dy;
      },
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;
        final vx = velocity.dx;
        final vy = velocity.dy;

        // Avalia tanto a velocidade quanto o deslocamento acumulado
        final isHorizontal = vx.abs() > vy.abs() || (vx == 0 && dragDx.abs() > dragDy.abs());

        if (isHorizontal) {
          if (vx < -100 || (vx.abs() < 50 && dragDx < -40)) {
            controller.nextMonth();
          } else if (vx > 100 || (vx.abs() < 50 && dragDx > 40)) {
            controller.previousMonth();
          }
        } else {
          if (vy < -100 || (vy.abs() < 50 && dragDy < -40)) {
            controller.nextYear();
          } else if (vy > 100 || (vy.abs() < 50 && dragDy > 40)) {
            controller.previousYear();
          }
        }

        dragDx = 0.0;
        dragDy = 0.0;
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          children: [
            _buildWeekDaysHeader(),
            const SizedBox(height: 6),
            _buildDaysGrid(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDaysHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _weekDayNames
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDaysGrid(ScheduleController controller) {
    final current = controller.currentMonth.value;
    final totalDaysInMonth = DateTime(current.year, current.month + 1, 0).day;
    final firstWeekday = DateTime(current.year, current.month, 1).weekday;
    // DateTime.weekday: Segunda=1 ... Domingo=7
    // Matriz onde Domingo=0:
    final offset = firstWeekday % 7;

    final cells = <Widget>[];

    // Células vazias antes do primeiro dia
    for (var i = 0; i < offset; i++) {
      cells.add(const SizedBox.shrink());
    }

    final today = DateTime.now();
    final selected = controller.selectedDate.value;

    for (var day = 1; day <= totalDaysInMonth; day++) {
      final date = DateTime(current.year, current.month, day);
      final isToday = today.year == date.year &&
          today.month == date.month &&
          today.day == date.day;
      final isSelected = selected != null &&
          selected.year == date.year &&
          selected.month == date.month &&
          selected.day == date.day;
      final count = controller.countForDate(date);

      cells.add(
        _ScheduleDayCell(
          date: date,
          isToday: isToday,
          isSelected: isSelected,
          orderCount: count,
          onTap: () => controller.selectDate(date),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.6,
      children: cells,
    );
  }

  Widget _buildAppointmentsSection(ScheduleController controller) {
    final selected = controller.selectedDate.value;
    final appointments = controller.selectedDateWorkOrders;

    final dateStr = selected != null
        ? '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Atendimentos em $dateStr',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                '${appointments.length} agendada${appointments.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: appointments.isEmpty
              ? const Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            size: 48,
                            color: AppColors.gray500,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sem atendimentos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Nenhum atendimento agendado para este dia.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.gray500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: appointments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = appointments[index];
                    return _AppointmentCard(
                      workOrder: item,
                      onTap: onWorkOrderTapped != null
                          ? () => onWorkOrderTapped!(item.id)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ScheduleDayCell extends StatelessWidget {
  const _ScheduleDayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.orderCount,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final int orderCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    Color textColor = AppColors.gray900;

    if (isSelected) {
      decoration = BoxDecoration(
        color: AppColors.primaryAction,
        borderRadius: BorderRadius.circular(10),
      );
      textColor = Colors.white;
    } else if (isToday) {
      decoration = BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryAction, width: 1.5),
      );
      textColor = AppColors.primaryAction;
    } else {
      decoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: decoration,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
            if (orderCount > 0)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.primaryAction,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.workOrder,
    this.onTap,
  });

  final WorkOrder workOrder;
  final VoidCallback? onTap;

  (String, AppStatusTone) _mapStatus(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.scheduled:
        return ('Agendada', AppStatusTone.info);
      case WorkOrderStatus.inProgress:
        return ('Em Atendimento', AppStatusTone.warning);
      case WorkOrderStatus.paused:
        return ('Pausada', AppStatusTone.warning);
      case WorkOrderStatus.completed:
        return ('Concluída', AppStatusTone.success);
      case WorkOrderStatus.cancelled:
        return ('Cancelada', AppStatusTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusTone) = _mapStatus(workOrder.status);
    final timeStr = DateFormat('HH:mm').format(workOrder.scheduledAt.toLocal());

    return Card(
      elevation: 0,
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.gray700),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workOrder.serviceDescription,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'OS #${workOrder.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: statusLabel,
                tone: statusTone,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
