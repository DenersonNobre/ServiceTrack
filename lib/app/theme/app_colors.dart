// Fonte única de verdade de cores do ServiceTrack (Styleguide v2.1).
//
// SRP: centraliza TODOS os tokens de cor (Light, Dark e Soft Badges).
// Nenhum outro arquivo de tema ou widget deve declarar `Color(0xFF...)` literal.

import 'package:flutter/material.dart';

/// Cores canônicas do ServiceTrack.
abstract final class AppColors {
  // === Primárias & Superfícies (Light) ===

  /// Ação primária / CTA (Deep Petrol Green).
  static const primaryAction = Color(0xFF115E59);

  /// Pressed/splash primário.
  static const primaryHover = Color(0xFF0F4C47);

  /// Container primário suave (Light).
  static const primaryContainer = Color(0xFFCCFBF1);

  /// Cor terciária informativa (Light).
  static const tertiary = Color(0xFF0369A1);

  /// Fundo principal (Warm Surface).
  static const surface = Color(0xFFFBF9F5);

  /// Card elevado.
  static const surfaceCard = Color(0xFFFFFFFF);

  /// Borda sutil.
  static const border = Color(0xFFE2DDD5);

  // === Escala de Cinzas ===

  /// Texto alta ênfase.
  static const gray900 = Color(0xFF18181B);

  /// Texto leitura.
  static const gray700 = Color(0xFF3F3F46);

  /// Rótulo secundário.
  static const gray500 = Color(0xFF71717A);

  /// Fundo neutro de chip/input.
  static const gray100 = Color(0xFFF4F4F5);

  // === Dark Mode ===

  /// Primária em modo escuro.
  static const darkPrimary = Color(0xFF2DD4BF);

  /// Secundária em modo escuro.
  static const darkSecondary = Color(0xFF5EEAD4);

  /// Container secundário em modo escuro.
  static const darkSecondaryContainer = Color(0xFF134E4A);

  /// Terciária em modo escuro.
  static const darkTertiary = Color(0xFF38BDF8);

  /// Container terciário em modo escuro.
  static const darkTertiaryContainer = Color(0xFF0C4A6E);

  /// Erro em modo escuro.
  static const darkError = Color(0xFFEF4444);

  // === Soft Badges / Status Semânticos ===

  /// Sucesso (fundo, borda, texto).
  static const successBg = Color(0xFFEBF8F0);
  static const successBorder = Color(0xFFA3E6BA);
  static const successText = Color(0xFF166534);

  /// Informativo (fundo, borda, texto).
  static const infoBg = Color(0xFFEBF5FF);
  static const infoBorder = Color(0xFFA5D0FF);
  static const infoText = Color(0xFF1E40AF);

  /// Alerta / Pendente (fundo, borda, texto).
  static const warningBg = Color(0xFFFEF8E7);
  static const warningBorder = Color(0xFFFDE08B);
  static const warningText = Color(0xFF854D0E);

  /// Erro / Cancelado (fundo, borda, texto).
  static const errorBg = Color(0xFFFEEFEF);
  static const errorBorder = Color(0xFFFCA5A5);
  static const error = Color(0xFF991B1B);
}
