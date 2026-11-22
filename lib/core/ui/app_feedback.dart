// Helper transversal de feedback visual (SnackBar) no Styleguide v2.1.
//
// SRP: padronizar a exibição de mensagens de erro, sucesso e informação via
// ScaffoldMessenger sem duplicar estilo ou tratamento de contexto ausente.

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Utilitário de feedback visual padronizado para telas do ServiceTrack.
abstract final class AppFeedback {
  /// Exibe uma mensagem de erro com destaque semântico [AppColors.error].
  static void showError(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: AppColors.error);
  }

  /// Exibe uma mensagem de sucesso com destaque [AppColors.primaryAction].
  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: AppColors.primaryAction);
  }

  /// Exibe uma mensagem informativa neutra com destaque [AppColors.gray900].
  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: AppColors.gray900);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
