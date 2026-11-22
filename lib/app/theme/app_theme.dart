// Tema global do ServiceTrack isolado sobre flex_color_scheme (Styleguide v2.1).
//
// SRP: centralizar ThemeData Light/Dark consumindo exclusivamente AppColors.
// Nenhuma outra camada importa flex_color_scheme diretamente.

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Temas canônicos Light e Dark do ServiceTrack.
abstract final class AppTheme {
  /// Família tipográfica principal da interface (offline em assets/fonts/).
  static const fontSans = 'PlusJakartaSans';

  /// Família monoespaçada para códigos de OS, GPS e timestamps.
  static const fontMono = 'JetBrainsMono';

  static const FlexSchemeColor _lightColors = FlexSchemeColor(
    primary: AppColors.primaryAction,
    primaryContainer: AppColors.primaryContainer,
    secondary: AppColors.primaryHover,
    secondaryContainer: AppColors.border,
    tertiary: AppColors.tertiary,
    tertiaryContainer: AppColors.infoBg,
    error: AppColors.error,
  );

  static const FlexSchemeColor _darkColors = FlexSchemeColor(
    primary: AppColors.darkPrimary,
    primaryContainer: AppColors.primaryAction,
    secondary: AppColors.darkSecondary,
    secondaryContainer: AppColors.darkSecondaryContainer,
    tertiary: AppColors.darkTertiary,
    tertiaryContainer: AppColors.darkTertiaryContainer,
    error: AppColors.darkError,
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
        fontFamily: fontSans,
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
        fontFamily: fontSans,
        subThemesData: _subThemes,
        keyColors: const FlexKeyColors(
          useSecondary: true,
          keepPrimary: true,
        ),
        useMaterial3: true,
      );
}
