// Tela de recuperação de PIN (UC-01.04).
//
// SRP: renderizar fluxo de recuperação e delegar ações ao controller.
// Não valida regra de negócio nem acessa storage.
//
// Pattern: IKortexPage + KortexWatch.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../lock/widgets/pin_keypad.dart';
import 'pin_recovery_controller.dart';

/// Página de recuperação de PIN.
final class PinRecoveryPage extends IKortexPage<PinRecoveryController> {
  /// Cria a página.
  const PinRecoveryPage({super.key});

  @override
  Widget buildPage(BuildContext context, PinRecoveryController controller) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Recuperar PIN'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: KortexWatch(
                builder: (context, _) {
                  // Rastreia sinais lidos pelos subwidgets na árvore.
                  controller.loading.value;
                  controller.pinError.value;
                  controller.passwordError.value;
                  controller.newPin.value;
                  return switch (controller.step.value) {
                    PinRecoveryStep.chooseMethod => _ChooseMethod(controller: controller),
                    PinRecoveryStep.masterPassword => _MasterPassword(controller: controller),
                    PinRecoveryStep.newPin => _NewPin(controller: controller),
                    PinRecoveryStep.done => const _Done(),
                  };
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChooseMethod extends StatelessWidget {
  const _ChooseMethod({required this.controller});
  final PinRecoveryController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Esqueceu seu PIN?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.gray900,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        const Text('Escolha como confirmar sua identidade para criar um novo PIN.'),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton(
            key: const Key('recover-master-password'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryAction,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: controller.loading.value ? null : controller.chooseMasterPassword,
            child: const Text('Usar senha mestre'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            key: const Key('recover-device-credential'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: controller.loading.value ? null : controller.chooseDeviceCredential,
            child: const Text('Usar biometria/padrão do sistema'),
          ),
        ),
        if (controller.pinError.value != null) ...[
          const SizedBox(height: 12),
          Text(controller.pinError.value!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }
}

class _MasterPassword extends StatelessWidget {
  const _MasterPassword({required this.controller});
  final PinRecoveryController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Confirme sua senha mestre'),
        const SizedBox(height: 12),
        TextField(
          key: const Key('recover-password-field'),
          obscureText: true,
          onChanged: (v) => controller.masterPassword.value = v,
          decoration: InputDecoration(
            errorText: controller.passwordError.value,
            filled: true,
            fillColor: AppColors.surfaceCard,
            constraints: const BoxConstraints(minHeight: 48),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton(
            key: const Key('recover-password-submit'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryAction,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: controller.loading.value ? null : controller.submitMasterPassword,
            child: controller.loading.value
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Continuar'),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: controller.loading.value ? null : controller.backToChoose,
          child: const Text('Voltar'),
        ),
      ],
    );
  }
}

class _NewPin extends StatelessWidget {
  const _NewPin({required this.controller});
  final PinRecoveryController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cadastre um novo PIN',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.gray900,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        const Text('Digite o novo PIN numérico (4 a 6 dígitos).'),
        const SizedBox(height: 16),
        _PinDots(length: controller.newPin.value.length),
        if (controller.pinError.value != null) ...[
          const SizedBox(height: 8),
          Text(controller.pinError.value!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 16),
        if (controller.loading.value)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primaryAction)))
        else
          PinKeypad(
            onDigit: controller.appendDigit,
            onBackspace: controller.backspace,
            onSubmit: controller.submitNewPin,
          ),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: controller.loading.value ? null : controller.backToChoose,
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.check_circle, color: AppColors.primaryAction, size: 48),
        SizedBox(height: 12),
        Text('PIN redefinido com sucesso.'),
      ],
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.length});
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
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
