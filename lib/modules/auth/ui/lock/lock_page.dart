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
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('lock-pin-field'),
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => controller.pin.value = v,
                        decoration: InputDecoration(
                          errorText: controller.pinError.value,
                          filled: true,
                          fillColor: AppColors.surfaceCard,
                          constraints: const BoxConstraints(minHeight: 48),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryAction,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: controller.submittingPin.value
                              ? null
                              : controller.submitPin,
                          child: controller.submittingPin.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Desbloquear'),
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
