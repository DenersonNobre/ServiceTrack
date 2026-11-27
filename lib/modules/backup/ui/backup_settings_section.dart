import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:path/path.dart' as p;

import '../../../../app/theme/app_colors.dart';
import '../../../../core/.index.dart';
import 'backup_controller.dart';

/// Seção de configurações para Backup e Restauração Segura Local (UC-08.02, RF-13).
final class BackupSettingsSection extends StatelessWidget {
  const BackupSettingsSection({required this.controller, super.key});

  final BackupController controller;

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, _) {
        final status = controller.status.value;
        final isBusy = status != BackupOperationStatus.idle;
        final backups = controller.localBackups.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Segurança & Backup Local (RF-13)',
              style: TextStyle(
                color: AppColors.gray700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cópia de Segurança Autocontida',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryAction,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Exporte um arquivo criptografado (AES-GCM 256) protegido por senha '
                      'contendo clientes, locais, ordens de serviço, checklists e configurações.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            key: const Key('backup-export-button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAction,
                              foregroundColor: Colors.white,
                              minimumSize: kMinTouchTargetSize,
                            ),
                            onPressed: isBusy
                                ? null
                                : () => _showExportPasswordDialog(context),
                            icon: isBusy && status == BackupOperationStatus.exporting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.shield_outlined),
                            label: const Text('Exportar Backup'),
                          ),
                        ),
                      ],
                    ),
                    if (backups.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Backups Locais Disponíveis:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: backups.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final file = backups[index];
                          final name = p.basename(file.path);
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.file_present_outlined,
                              color: AppColors.primaryAction,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            trailing: TextButton(
                              key: Key('backup-restore-btn-$index'),
                              onPressed: isBusy
                                  ? null
                                  : () => _showRestorePasswordDialog(context, file.path),
                              child: const Text('Restaurar'),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showExportPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Senha de Proteção'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Defina uma senha com no mínimo 6 caracteres para cifrar o arquivo de backup.',
                style: TextStyle(fontSize: 13, color: AppColors.gray500),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('backup-export-password-field'),
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha do Backup',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            key: const Key('backup-export-confirm-button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAction,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final pwd = passwordController.text;
                Navigator.of(dialogCtx).pop();
                await controller.exportBackup(password: pwd);
              }
            },
            child: const Text('Gerar e Compartilhar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestorePasswordDialog(BuildContext context, String filePath) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Restaurar Backup'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Digite a senha utilizada na exportação deste arquivo para inspecionar os dados.',
                style: TextStyle(fontSize: 13, color: AppColors.gray500),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('backup-restore-password-field'),
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha de Decifragem',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe a senha de decifragem.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            key: const Key('backup-restore-inspect-button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAction,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final pwd = passwordController.text;
                Navigator.of(dialogCtx).pop();
                final ok = await controller.inspectBackup(
                  filePath: filePath,
                  password: pwd,
                );
                if (ok && context.mounted) {
                  await _showConfirmRestoreDialog(context, pwd);
                }
              }
            },
            child: const Text('Verificar Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmRestoreDialog(BuildContext context, String password) async {
    final meta = controller.inspectedMetadata.value;
    if (meta == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirmar Restauração'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A restauração substituirá atomicamente os dados atuais do aplicativo.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            Text('Versão do Schema: ${meta.schemaVersion}'),
            Text('Criado em: ${meta.createdAt.toLocal().toString().split('.')[0]}'),
            const SizedBox(height: 8),
            const Text('Registros a restaurar:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...meta.recordCounts.entries.map(
              (e) => Text(' • ${e.key}: ${e.value}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearSelection();
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            key: const Key('backup-confirm-overwrite-button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await controller.confirmRestore(password: password);
            },
            child: const Text('Substituir Dados'),
          ),
        ],
      ),
    );
  }
}
