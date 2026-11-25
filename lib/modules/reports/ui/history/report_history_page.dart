// Tela de histórico visual de laudos (UC-05.04).
//
// SRP: renderizar lista de OS concluídas elegíveis e acionar reabertura do laudo.
// Não carrega dados nem gera PDF; delega ao controller e callback.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/ui/app_touch_target.dart';
import 'report_history_controller.dart';

/// Tela de histórico de laudos técnicos.
final class ReportHistoryPage extends IKortexPage<ReportHistoryController> {
  const ReportHistoryPage({super.key, required this.onOpenReport});

  final void Function(String workOrderId) onOpenReport;

  @override
  Widget buildPage(BuildContext context, ReportHistoryController controller) {
    controller.ensureLoaded();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Histórico de Laudos'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.gray900,
        elevation: 0,
      ),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.loading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryAction),
              );
            }

            final error = controller.error.value;
            if (error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 56,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: kMinTouchTargetConstraints,
                        child: FilledButton.icon(
                          key: const Key('report-history-retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryAction,
                            foregroundColor: Colors.white,
                            minimumSize: kMinTouchTargetSize,
                          ),
                          onPressed: controller.load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final items = controller.items.value;
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 64,
                        color: AppColors.gray500,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum laudo disponível.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Conclua uma Ordem de Serviço para gerar e reabrir laudos aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  key: Key('report-history-item-${item.workOrderId}'),
                  color: AppColors.surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'OS #${item.workOrderId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryAction,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.successBorder,
                                ),
                              ),
                              child: Text(
                                item.status,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.successText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.serviceDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                        if (item.customerName != null &&
                            item.customerName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Cliente: ${item.customerName}',
                            style: const TextStyle(color: AppColors.gray700),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Agendada: ${item.scheduledDateFormatted}',
                          style: const TextStyle(color: AppColors.gray700),
                        ),
                        if (item.completedDateFormatted != null &&
                            item.completedDateFormatted!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Conclusão: ${item.completedDateFormatted}',
                            style: const TextStyle(color: AppColors.gray700),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: kMinTouchTargetConstraints,
                            child: FilledButton.icon(
                              key: Key(
                                'report-history-open-${item.workOrderId}',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryAction,
                                foregroundColor: Colors.white,
                                minimumSize: kMinTouchTargetSize,
                              ),
                              onPressed: () => onOpenReport(item.workOrderId),
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: const Text('Ver Laudo'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
