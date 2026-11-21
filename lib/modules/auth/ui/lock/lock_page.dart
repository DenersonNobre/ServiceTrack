// Tela de bloqueio/desbloqueio (UC-01.02).
//
// SRP: renderiza o gate de desbloqueio (biometria automática + PIN manual)
// e delega decisões ao LockController. Não contém regra de negócio.
//
// Pattern: IKortexPage + KortexWatch.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import 'lock_controller.dart';
import 'widgets/pin_keypad.dart';

/// Página de bloqueio com biometria e PIN manual.
final class LockPage extends IKortexPage<LockController> {
  /// Cria a página de bloqueio.
  const LockPage({super.key});

  @override
  Widget buildPage(BuildContext context, LockController controller) {
    controller.ensureInitialized();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: KortexWatch(
                builder: (context, _) {
                  if (controller.checkingBiometric.value && !controller.showPin.value) {
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryAction),
                        SizedBox(height: 16),
                        Text('Verificando identidade...'),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'App bloqueado',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.gray900,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Digite seu PIN para continuar.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray700,
                            ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Digite seu PIN'),
                      const SizedBox(height: 12),
                      _PinDots(length: controller.pin.value.length),
                      if (controller.pinError.value != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          controller.pinError.value!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (controller.submittingPin.value)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: AppColors.primaryAction,
                            ),
                          ),
                        )
                      else
                        PinKeypad(
                          onDigit: controller.appendDigit,
                          onBackspace: controller.backspace,
                          onSubmit: controller.submitPin,
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          key: const Key('lock-forgot-pin'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: AppColors.primaryAction,
                          ),
                          onPressed: controller.forgotPin,
                          child: const Text('Esqueci meu PIN'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.length});
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('lock-pin-dots'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: filled ? AppColors.primaryAction : Colors.transparent,
            border: Border.all(color: AppColors.primaryAction, width: 1.5),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
