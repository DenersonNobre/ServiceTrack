// Estado vazio canônico de tela/lista (DESIGN.md §3).
//
// SRP: apresentar feedback claro de lista vazia com CTA opcional >= 48dp.

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'app_primary_button.dart';

/// Widget reutilizável para estado vazio de módulos.
final class AppEmptyState extends StatelessWidget {
  /// Cria o estado vazio.
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.imageAsset,
    this.imageSize = 140,
    this.actionLabel,
    this.onAction,
  });

  /// Ícone ilustrativo central (fallback quando [imageAsset] não é informado).
  final IconData icon;

  /// Caminho opcional de ilustração PNG transparente em `assets/images/`.
  final String? imageAsset;

  /// Tamanho máximo da ilustração quando [imageAsset] é informado.
  final double imageSize;

  /// Título principal.
  final String title;

  /// Mensagem explicativa de apoio.
  final String message;

  /// Rótulo opcional do botão de ação primária.
  final String? actionLabel;

  /// Callback opcional do botão de ação.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageAsset != null)
                Image.asset(
                  imageAsset!,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      Icon(icon, size: 48, color: AppColors.gray500),
                )
              else
                Icon(icon, size: 48, color: AppColors.gray500),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.gray900,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray700,
                    ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
