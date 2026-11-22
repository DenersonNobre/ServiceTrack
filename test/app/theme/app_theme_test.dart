import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/app/theme/app_colors.dart';
import 'package:service_track/app/theme/app_theme.dart';

void main() {
  group('AppTheme (flex_color_scheme — Styleguide v2.1)', () {
    test('light preserva Deep Petrol Green (#115E59) e surface (#FBF9F5)', () {
      final theme = AppTheme.light;
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primaryAction);
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
    });

    test('dark gera tema escuro Material 3 valido', () {
      final theme = AppTheme.dark;
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });
  });
}
