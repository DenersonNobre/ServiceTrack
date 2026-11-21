// Tokens de cor do Styleguide v2.1 (Deep Petrol Green).
//
// SRP: centraliza cores semânticas do ServiceTrack. Não conhece widgets,
// rotas ou estado. Consumido por temas e telas.
//
// Dependências: Flutter Material (Color).

import 'package:flutter/material.dart';

/// Cores canônicas do ServiceTrack.
abstract final class AppColors {
  /// Ação primária / CTA (Deep Petrol Green).
  static const primaryAction = Color(0xFF115E59);

  /// Pressed/splash primário.
  static const primaryHover = Color(0xFF0F4C47);

  /// Fundo principal.
  static const surface = Color(0xFFFBF9F5);

  /// Card elevado.
  static const surfaceCard = Color(0xFFFFFFFF);

  /// Borda sutil.
  static const border = Color(0xFFE2DDD5);

  /// Texto alta ênfase.
  static const gray900 = Color(0xFF18181B);

  /// Texto leitura.
  static const gray700 = Color(0xFF3F3F46);

  /// Rótulo secundário.
  static const gray500 = Color(0xFF71717A);

  /// Erro.
  static const error = Color(0xFF991B1B);
}
