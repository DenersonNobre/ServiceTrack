// Interface visual de Preview do Laudo Técnico (UC-05.02 / UC-05.03).
//
// SRP: Renderizar resumo executivo do laudo, status de compilação, ilustração e botões
// de ação com alvos táteis mínimos de 48dp x 48dp e cores canônicas (Deep Petrol Green #115E59).

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/ui/app_touch_target.dart';
import 'report_preview_controller.dart';

/// Tela de pré-visualização e envio com 1 toque do Laudo Técnico.
final class ReportPreviewPage extends IKortexPage<ReportPreviewController> {
  const ReportPreviewPage({super.key});

  @override
  Widget buildPage(BuildContext context, ReportPreviewController controller) {
    controller.ensureInitialized();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Laudo Técnico'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.gray900,
        elevation: 0,
      ),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.loading.value) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryAction),
                    SizedBox(height: 16),
                    Text(
                      'Gerando Laudo PDF executivo...',
                      style: TextStyle(fontSize: 14, color: AppColors.gray700),
                    ),
                  ],
                ),
              );
            }

            if (controller.errorMessage.value != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: kMinTouchTargetConstraints,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryAction,
                            foregroundColor: Colors.white,
                            minimumSize: kMinTouchTargetSize,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: controller.generate,
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text('Tentar Novamente'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = controller.reportData;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ilustração ou Ícone de Laudo Pronto
                  Center(
                    child: Image.asset(
                      'assets/images/report_pdf_ready.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          size: 48,
                          color: AppColors.primaryAction,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resumo Executivo em Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    color: AppColors.surfaceCard,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'OS #${data.workOrderId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryAction,
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
                                  border: Border.all(color: AppColors.successBorder),
                                ),
                                child: Text(
                                  data.status,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.successText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (data.customerName != null) ...[
                            _buildInfoRow('Cliente', data.customerName!),
                            const SizedBox(height: 8),
                          ],
                          _buildInfoRow('Data Agendada', data.scheduledDateFormatted),
                          if (data.completedDateFormatted != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow('Conclusão', data.completedDateFormatted!),
                          ],
                          const SizedBox(height: 8),
                          _buildInfoRow('Serviço', data.serviceDescription),
                          if (data.estimatedAmountFormatted != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow('Valor', data.estimatedAmountFormatted!),
                          ],
                          if (data.checklistItems.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Checklist',
                              '${data.checklistItems.length} itens verificados',
                            ),
                          ],
                          if (data.photos.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Evidências',
                              '${data.photos.length} fotos anexadas',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botão CTA de Compartilhamento Nativo com 1 Toque (UC-05.03)
                  ConstrainedBox(
                    constraints: kMinTouchTargetConstraints,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryAction,
                        foregroundColor: Colors.white,
                        minimumSize: kMinTouchTargetSize,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: controller.sharing.value ? null : controller.share,
                      icon: controller.sharing.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share, size: 20),
                      label: Text(
                        controller.sharing.value
                            ? 'Preparando Envio...'
                            : 'Compartilhar Laudo PDF',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.gray500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
        ),
      ],
    );
  }
}
