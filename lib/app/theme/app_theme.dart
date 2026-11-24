// Tema global do ServiceTrack isolado sobre flex_color_scheme (Styleguide v2.1).
//
// SRP: centralizar ThemeData Light/Dark consumindo exclusivamente AppColors.
// Nenhuma outra camada importa flex_color_scheme diretamente.

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Temas canônicos Light e Dark do ServiceTrack.
abstract final class AppTheme {
  /// Família tipográfica para títulos e destaque de impacto.
  static const fontOswald = 'Oswald';

  /// Família tipográfica principal para corpo, rótulos e interface compacta.
  static const fontBody = 'RobotoCondensed';

  /// Família tipográfica legado mantida para compatibilidade com relatórios.
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

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      // Títulos e Headlines com Oswald
      displayLarge: TextStyle(
        fontFamily: fontOswald,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: fontOswald,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontFamily: fontOswald,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontOswald,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontOswald,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.0,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontOswald,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
      ),
      titleLarge: TextStyle(
        fontFamily: fontOswald,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      // Corpo e rótulos com Roboto Condensed
      titleMedium: TextStyle(
        fontFamily: fontBody,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontFamily: fontBody,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontBody,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontBody,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontFamily: fontBody,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontFamily: fontBody,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontFamily: fontBody,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: fontBody,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Tema claro canônico (Styleguide v2.1 — Warm Surface + Deep Petrol Green).
  static ThemeData get light => FlexThemeData.light(
        colors: _lightColors,
        scaffoldBackground: AppColors.surface,
        surface: AppColors.surfaceCard,
        fontFamily: fontBody,
        textTheme: _buildTextTheme(),
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
        fontFamily: fontBody,
        textTheme: _buildTextTheme(),
        subThemesData: _subThemes,
        keyColors: const FlexKeyColors(
          useSecondary: true,
          keepPrimary: true,
        ),
        useMaterial3: true,
      );
}
