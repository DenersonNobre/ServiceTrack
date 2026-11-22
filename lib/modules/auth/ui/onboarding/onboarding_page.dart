// Tela de Onboarding inicial do técnico (UC-01.01, TASK-03).
//
// SRP: renderiza o formulário de cadastro inicial com os tokens do
// Styleguide (Deep Petrol Green, alvos >=48dp) e delega validação/persistência
// ao OnboardingController. Não contém regra de negócio nem acesso a storage.
//
// Pattern: IKortexPage + KortexWatch (reatividade granular).

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import 'onboarding_controller.dart';

/// Página de onboarding com cadastro de credenciais locais.
final class OnboardingPage extends IKortexPage<OnboardingController> {
  /// Cria a página de onboarding.
  const OnboardingPage({super.key});

  @override
  Widget buildPage(BuildContext context, OnboardingController controller) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: KortexWatch(
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/onboarding_welcome.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crie seu acesso',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.gray900,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure seus dados para proteger o app e personalizar seus laudos.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray700,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Nome completo',
                        error: controller.nameError.value,
                        onChanged: (v) => controller.name.value = v,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        label: 'E-mail',
                        error: controller.emailError.value,
                        onChanged: (v) => controller.email.value = v,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        label: 'Senha mestre',
                        error: controller.passwordError.value,
                        onChanged: (v) => controller.password.value = v,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        label: 'PIN (4 a 6 dígitos)',
                        error: controller.pinError.value,
                        onChanged: (v) => controller.pin.value = v,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => controller.submit(),
                      ),
                      const SizedBox(height: 16),
                      if (controller.submitError.value != null) ...[
                        Text(
                          controller.submitError.value!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (controller.submitted.value) ...[
                        const Text(
                          'Conta criada com sucesso.',
                          style: TextStyle(
                            color: AppColors.primaryAction,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryAction,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: controller.isSubmitting.value
                              ? null
                              : controller.submit,
                          child: controller.isSubmitting.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Criar conta'),
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

final class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.error,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String? error;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        filled: true,
        fillColor: AppColors.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 48),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryAction, width: 1.5),
        ),
      ),
    );
  }
}
