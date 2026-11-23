// Widget de coleta de assinatura digital em canvas (UC-04.04 / DESIGN.md §4.3).
//
// SRP: renderizar canvas + nome + documento e emitir DigitalSignature validada.
// Estado de tela vive no SignaturePadController (KortexSignal); este widget é
// stateless e não guarda estado próprio (UC-06.03).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:signature/signature.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/ui/app_primary_button.dart';
import '../../../../core/ui/app_touch_target.dart';
import '../../domain/entities/digital_signature.dart';
import 'signature_pad_controller.dart';

/// Canvas tátil para coleta de assinatura digital do cliente.
final class SignaturePadWidget extends StatelessWidget {
  /// Cria o widget de coleta de assinatura.
  ///
  /// O [controller] pertence ao chamador (crie-o em um `KortexScope` ou no
  /// `State` da tela) e é responsável pelo `dispose`.
  const SignaturePadWidget({
    super.key,
    required this.controller,
    required this.onConfirmed,
    this.requireDocumentByPolicy = false,
  });

  /// Controller reativo da captura.
  final SignaturePadController controller;

  /// Callback acionado com [DigitalSignature] validada.
  final void Function(DigitalSignature signature) onConfirmed;

  /// Política C-03: documento obrigatório apenas quando habilitado (default minimização).
  final bool requireDocumentByPolicy;

  Future<void> _confirm() async {
    final result = await controller.confirm(
      requireDocumentByPolicy: requireDocumentByPolicy,
    );
    if (result case Success(:final value)) onConfirmed(value);
  }

  @override
  Widget build(BuildContext context) {
    return KortexWatch(
      builder: (context, _) {
        final saving = controller.saving.value;
        final error = controller.error.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  key: const Key('signature-canvas'),
                  controller: controller.signatureController,
                  backgroundColor: AppColors.surfaceCard,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('signature-signer-name'),
              controller: controller.signerNameController,
              decoration: InputDecoration(
                labelText: 'Nome completo do recebedor',
                filled: true,
                fillColor: AppColors.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (requireDocumentByPolicy) ...[
              const SizedBox(height: 12),
              TextField(
                key: const Key('signature-signer-doc'),
                controller: controller.signerDocumentController,
                decoration: InputDecoration(
                  labelText: 'Documento (CPF/RG)',
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('signature-clear'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: kMinTouchTargetSize,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: saving ? null : controller.clear,
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    key: const Key('signature-confirm'),
                    label: 'Confirmar',
                    loading: saving,
                    onPressed: _confirm,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
