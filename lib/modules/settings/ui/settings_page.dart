import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/.index.dart';
import 'settings_controller.dart';

/// Tela de configurações locais (UC-07.02).
final class SettingsPage extends IKortexPage<SettingsController> {
  const SettingsPage({super.key});

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
                if (loadError != null) {
                  return Center(
                    child: Text(
                      loadError,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }
                final snapshot = controller.snapshot.value;
                final saving = controller.saving.value;
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
                        'A persistência depende da proteção em repouso (D-01).',
                      ),
                      value: snapshot.requireReceiverDocument,
                      onChanged: saving
                          ? null
                          : controller.setRequireReceiverDocument,
                    ),
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
