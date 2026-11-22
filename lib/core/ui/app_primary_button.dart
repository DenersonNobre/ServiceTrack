// Botão primário tátil de campo (Styleguide v2.1 — Deep Petrol Green).
//
// SRP: renderizar CTA primário com alvo mínimo de 48dp e estado loading.

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'app_touch_target.dart';

/// Botão primário canônico do ServiceTrack (alvo tátil >= 48dp).
final class AppPrimaryButton extends StatelessWidget {
  /// Cria o botão primário.
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  /// Rótulo exibido no botão.
  final String label;

  /// Callback de clique (null desabilita o botão).
  final VoidCallback? onPressed;

  /// Quando verdadeiro, exibe indicador de progresso e bloqueia cliques.
  final bool loading;

  /// Ícone opcional à esquerda do rótulo.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return ConstrainedBox(
      constraints: kMinTouchTargetConstraints,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryAction,
          foregroundColor: Colors.white,
          disabledBackgroundColor: loading ? AppColors.primaryAction : null,
          disabledForegroundColor: loading ? Colors.white : null,
          overlayColor: AppColors.primaryHover,
          elevation: 1,
          minimumSize: kMinTouchTargetSize,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: child,
      ),
    );
  }
}
