import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/.index.dart';
import '../../backup/.index.dart';
import 'settings_controller.dart';

/// Tela de configurações locais (UC-07.02).
final class SettingsPage extends IKortexPage<SettingsController> {
  const SettingsPage({this.backupController, super.key});

  final BackupController? backupController;

  @override
  Widget buildPage(BuildContext context, SettingsController controller) {
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Configurações'),
      ),
      body: SafeArea(
        child: KortexListener<String?>(
          watch: () => controller.error.value,
          listener: (context, message) {
            if (message != null) AppFeedback.showError(context, message);
          },
          child: KortexListener<String?>(
            watch: () => controller.success.value,
            listener: (context, message) {
              if (message != null) AppFeedback.showSuccess(context, message);
            },
            child: KortexWatch(
              builder: (context, _) {
                if (controller.loading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryAction,
                    ),
                  );
                }
                final loadError = controller.loadError.value;
                final saving = controller.saving.value;
                if (loadError != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loadError,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            key: const Key('settings-restore-defaults'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: kMinTouchTargetSize,
                            ),
                            onPressed: saving
                                ? null
                                : controller.restoreDefaults,
                            icon: const Icon(Icons.restore),
                            label: const Text('Restaurar padrões'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final snapshot = controller.snapshot.value;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Políticas de operação',
                      style: TextStyle(
                        color: AppColors.gray700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      key: const Key('settings-require-checklist'),
                      minTileHeight: 56,
                      secondary: const Icon(
                        Icons.checklist_outlined,
                        color: AppColors.primaryAction,
                      ),
                      title: const Text('Exigir checklist na conclusão'),
                      subtitle: const Text(
                        'Bloqueia a conclusão da OS sem checklist/template válido.',
                      ),
                      value: snapshot.requireChecklistTemplate,
                      onChanged: saving
                          ? null
                          : controller.setRequireChecklistTemplate,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      key: const Key('settings-require-receiver-document'),
                      minTileHeight: 56,
                      secondary: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.primaryAction,
                      ),
                      title: const Text('Exigir documento do recebedor'),
                      subtitle: const Text(
                        'Coleta CPF/RG na assinatura. Default: desativado (minimização LGPD). '
                        'Enquanto a proteção em repouso (D-01) não estiver concluída, '
                        'habilitar esta política bloqueia a conclusão.',
                      ),
                      value: snapshot.requireReceiverDocument,
                      onChanged: saving
                          ? null
                          : controller.setRequireReceiverDocument,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Jornada de Trabalho (Agenda)',
                      style: TextStyle(
                        color: AppColors.gray700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      key: const Key('settings-schedule-day-start'),
                      leading: const Icon(Icons.wb_sunny_outlined, color: AppColors.primaryAction),
                      title: const Text('Início da jornada'),
                      subtitle: Text('Horário inicial da grade diária: ${snapshot.scheduleDayStart}'),
                      trailing: Text(
                        snapshot.scheduleDayStart,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: saving ? null : () async {
                        final parts = snapshot.scheduleDayStart.split(':');
                        final initialHour = int.tryParse(parts[0]) ?? 8;
                        final initialMin = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
                        );
                        if (picked != null) {
                          final h = picked.hour.toString().padLeft(2, '0');
                          final m = picked.minute.toString().padLeft(2, '0');
                          await controller.setScheduleDayStart('$h:$m');
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('settings-schedule-day-end'),
                      leading: const Icon(Icons.nightlight_outlined, color: AppColors.primaryAction),
                      title: const Text('Fim da jornada'),
                      subtitle: Text('Horário final da grade diária: ${snapshot.scheduleDayEnd}'),
                      trailing: Text(
                        snapshot.scheduleDayEnd,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: saving ? null : () async {
                        final parts = snapshot.scheduleDayEnd.split(':');
                        final initialHour = int.tryParse(parts[0]) ?? 18;
                        final initialMin = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
                        );
                        if (picked != null) {
                          final h = picked.hour.toString().padLeft(2, '0');
                          final m = picked.minute.toString().padLeft(2, '0');
                          await controller.setScheduleDayEnd('$h:$m');
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('settings-schedule-interval'),
                      leading: const Icon(Icons.timer_outlined, color: AppColors.primaryAction),
                      title: const Text('Intervalo da grade'),
                      subtitle: const Text('Duração de cada intervalo de horário'),
                      trailing: DropdownButton<int>(
                        value: snapshot.scheduleSlotInterval,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 min')),
                          DropdownMenuItem(value: 30, child: Text('30 min')),
                          DropdownMenuItem(value: 60, child: Text('60 min')),
                        ],
                        onChanged: saving
                            ? null
                            : (val) {
                                if (val != null) {
                                  controller.setScheduleSlotInterval(val);
                                }
                              },
                      ),
                    ),
                    if (backupController != null) ...[
                      const Divider(height: 32),
                      BackupSettingsSection(controller: backupController!),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
