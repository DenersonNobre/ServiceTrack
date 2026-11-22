import 'package:flutter/material.dart';

import '../../../../core/.index.dart';
import '../domain/.index.dart';
import '../features/.index.dart';
import 'settings_controller.dart';
import 'settings_page.dart';

/// Bindings de navegação do módulo de configurações.
final class SettingsRoutes {
  const SettingsRoutes({required this.settingsRepository});

  final ISettingsRepositoryPort settingsRepository;

  /// Tela de configurações locais.
  Route<void> edit() {
    return appScopedRoute<SettingsController, void>(
      create: (_) => SettingsController(
        getSettings: GetSettings(repository: settingsRepository),
        updateSetting: UpdateSetting(repository: settingsRepository),
      ),
      builder: (_, _) => const SettingsPage(),
    );
  }
}
