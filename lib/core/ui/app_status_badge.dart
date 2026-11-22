// Badge semântico de status (Styleguide v2.1 — Soft Badges com borda).
//
// SRP: renderizar pílula de status com contraste WCAG AA.

import 'package:flutter/material.dart';

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
          const Color(0xFFEBF8F0),
          const Color(0xFFA3E6BA),
          const Color(0xFF166534),
        ),
      AppStatusTone.info => (
          const Color(0xFFEBF5FF),
          const Color(0xFFA5D0FF),
          const Color(0xFF1E40AF),
        ),
      AppStatusTone.warning => (
          const Color(0xFFFEF8E7),
          const Color(0xFFFDE08B),
          const Color(0xFF854D0E),
        ),
      AppStatusTone.error => (
          const Color(0xFFFEEFEF),
          const Color(0xFFFCA5A5),
          const Color(0xFF991B1B),
        ),
    };
  }
}
