// Tema global do ServiceTrack isolado sobre flex_color_scheme (Styleguide v2.1).
//
// SRP: centralizar ThemeData Light/Dark preservando Deep Petrol Green (#115E59),
// superfícies quentes (#FBF9F5) e raios de borda do DESIGN.md.
// Nenhuma outra camada importa flex_color_scheme diretamente.

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Temas canônicos Light e Dark do ServiceTrack.
abstract final class AppTheme {
  static const FlexSchemeColor _lightColors = FlexSchemeColor(
    primary: AppColors.primaryAction,
    primaryContainer: Color(0xFFCCFBF1),
    secondary: AppColors.primaryHover,
    secondaryContainer: Color(0xFFE2DDD5),
    tertiary: Color(0xFF0369A1),
    tertiaryContainer: Color(0xFFEBF5FF),
    error: AppColors.error,
  );

  static const FlexSchemeColor _darkColors = FlexSchemeColor(
    primary: Color(0xFF2DD4BF),
    primaryContainer: AppColors.primaryAction,
    secondary: Color(0xFF5EEAD4),
    secondaryContainer: Color(0xFF134E4A),
    tertiary: Color(0xFF38BDF8),
    tertiaryContainer: Color(0xFF0C4A6E),
    error: Color(0xFFEF4444),
  );

  static const FlexSubThemesData _subThemes = FlexSubThemesData(
    defaultRadius: 12,
    inputDecoratorRadius: 8,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    chipRadius: 24,
    cardRadius: 12,
    dialogRadius: 16,
    bottomSheetRadius: 16,
    filledButtonRadius: 12,
    outlinedButtonRadius: 12,
    textButtonRadius: 12,
    interactionEffects: true,
    tintedDisabledControls: true,
  );

  /// Tema claro canônico (Styleguide v2.1 — Warm Surface + Deep Petrol Green).
  static ThemeData get light => FlexThemeData.light(
        colors: _lightColors,
        scaffoldBackground: AppColors.surface,
        surface: AppColors.surfaceCard,
        subThemesData: _subThemes,
        keyColors: const FlexKeyColors(
          useSecondary: true,
          keepPrimary: true,
        ),
        useMaterial3: true,
      );

  /// Tema escuro harmônico derivado do mesmo seed Deep Petrol Green.
  static ThemeData get dark => FlexThemeData.dark(
        colors: _darkColors,
        subThemesData: _subThemes,
        keyColors: const FlexKeyColors(
          useSecondary: true,
          keepPrimary: true,
        ),
        useMaterial3: true,
      );
}
