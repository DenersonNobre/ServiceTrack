// Badge semântico de status (Styleguide v2.1 — Soft Badges com borda).
//
// SRP: renderizar pílula de status consumindo exclusivamente AppColors.

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Variantes semânticas de status do Styleguide v2.1.
enum AppStatusTone {
  /// Concluído, Conforme, Sync OK.
  success,

  /// Agendada, Informativo.
  info,

  /// Em Atendimento, Pendência, Não se Aplica.
  warning,

  /// Não Conforme, Cancelada, Erro.
  error,
}

/// Pílula semântica de status (radius 24px / full pill).
final class AppStatusBadge extends StatelessWidget {
  /// Cria o badge com [label] e [tone].
  const AppStatusBadge({
    super.key,
    required this.label,
    required this.tone,
  });

  /// Texto curto do status.
  final String label;

  /// Tom semântico da paleta oficial.
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = _paletteOf(tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static (Color, Color, Color) _paletteOf(AppStatusTone tone) {
    return switch (tone) {
      AppStatusTone.success => (
          AppColors.successBg,
          AppColors.successBorder,
          AppColors.successText,
        ),
      AppStatusTone.info => (
          AppColors.infoBg,
          AppColors.infoBorder,
          AppColors.infoText,
        ),
      AppStatusTone.warning => (
          AppColors.warningBg,
          AppColors.warningBorder,
          AppColors.warningText,
        ),
      AppStatusTone.error => (
          AppColors.errorBg,
          AppColors.errorBorder,
          AppColors.error,
        ),
    };
  }
}
