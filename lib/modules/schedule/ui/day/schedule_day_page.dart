// Tela de Agenda Diária com Timeline Vertical (UC-03.01, UC-05.02).
//
// SRP: renderizar timeline vertical das horas da jornada e os compromissos agendados.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/ui/app_status_badge.dart';
import '../../../../core/ui/app_touch_target.dart';
import '../../../work_orders/domain/value_objects/work_order.dart';
import '../../../work_orders/domain/value_objects/work_order_status.dart';
import 'schedule_day_controller.dart';

/// Página de Agenda Diária.
final class ScheduleDayPage extends IKortexPage<ScheduleDayController> {
  const ScheduleDayPage({
    super.key,
    this.onWorkOrderTapped,
    this.onEmptySlotTapped,
  });

  /// Callback ao tocar em uma Ordem de Serviço.
  final void Function(String workOrderId)? onWorkOrderTapped;

  /// Callback ao tocar em um horário livre (abre cadastro pré-preenchido).
  final void Function(DateTime date, String time)? onEmptySlotTapped;

  static const _weekDayNames = <int, String>{
    DateTime.monday: 'Segunda-feira',
    DateTime.tuesday: 'Terça-feira',
    DateTime.wednesday: 'Quarta-feira',
    DateTime.thursday: 'Quinta-feira',
    DateTime.friday: 'Sexta-feira',
    DateTime.saturday: 'Sábado',
    DateTime.sunday: 'Domingo',
  };

  static const _monthNames = <int, String>{
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

  @override
  Widget buildPage(BuildContext context, ScheduleDayController controller) {
    controller.ensureLoaded();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Agenda Diária'),
        actions: [
          TextButton.icon(
            key: const Key('schedule-day-today'),
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
              _buildDateNavigation(controller),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: _buildTimeline(controller),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateNavigation(ScheduleDayController controller) {
    final date = controller.selectedDate.value;
    final weekday = _weekDayNames[date.weekday] ?? '';
    final month = _monthNames[date.month] ?? '';
    final formatted = '$weekday, ${date.day} de $month de ${date.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('schedule-day-prev'),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Dia anterior',
            constraints: kMinTouchTargetConstraints,
            onPressed: controller.previousDay,
          ),
          Expanded(
            child: Text(
              formatted,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
          ),
          IconButton(
            key: const Key('schedule-day-next'),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próximo dia',
            constraints: kMinTouchTargetConstraints,
            onPressed: controller.nextDay,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ScheduleDayController controller) {
    final slots = controller.timeSlots.value;

    if (slots.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum horário configurado para a jornada.',
          style: TextStyle(color: AppColors.gray500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final timeSlot = slots[index];
        final appointments = controller.workOrdersForSlot(timeSlot);

        return _TimelineSlotRow(
          timeSlot: timeSlot,
          appointments: appointments,
          onWorkOrderTapped: onWorkOrderTapped,
          onEmptySlotTapped: () {
            if (onEmptySlotTapped != null) {
              onEmptySlotTapped!(controller.selectedDate.value, timeSlot);
            }
          },
        );
      },
    );
  }
}

class _TimelineSlotRow extends StatelessWidget {
  const _TimelineSlotRow({
    required this.timeSlot,
    required this.appointments,
    this.onWorkOrderTapped,
    required this.onEmptySlotTapped,
  });

  final String timeSlot;
  final List<WorkOrder> appointments;
  final void Function(String workOrderId)? onWorkOrderTapped;
  final VoidCallback onEmptySlotTapped;

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
    final hasAppointments = appointments.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coluna de horário
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 14, left: 16),
              child: Text(
                timeSlot,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray700,
                ),
              ),
            ),
          ),
          // Linha divisória vertical
          Container(
            width: 2,
            color: hasAppointments ? AppColors.primaryAction : AppColors.border,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          // Conteúdo do slot (compromissos ou área livre)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
              child: hasAppointments
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: appointments.map((wo) {
                        final (statusLabel, statusTone) = _mapStatus(wo.status);
                        return Card(
                          key: Key('schedule-appointment-${wo.id}'),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 6),
                          color: AppColors.primaryContainer.withAlpha(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.primaryAction, width: 1),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: onWorkOrderTapped != null
                                ? () => onWorkOrderTapped!(wo.id)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          wo.serviceDescription,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.gray900,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AppStatusBadge(
                                        label: statusLabel,
                                        tone: statusTone,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'OS #${wo.id}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : InkWell(
                      key: Key('schedule-slot-$timeSlot'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: onEmptySlotTapped,
                      child: Container(
                        height: 48,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Livre — Toque para agendar',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.gray500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
