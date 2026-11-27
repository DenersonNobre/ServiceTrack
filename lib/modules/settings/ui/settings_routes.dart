import 'package:flutter/material.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import '../../../../core/.index.dart';
import '../../backup/.index.dart';
import '../data/settings_sqlite_repository.dart';
import '../domain/.index.dart';
import '../features/.index.dart';
import 'settings_controller.dart';
import 'settings_page.dart';

/// Bindings de navegação do módulo de configurações.
final class SettingsRoutes {
  const SettingsRoutes({
    required this.settingsRepository,
    this.backupController,
  });

  factory SettingsRoutes.fromDatabase(SqliteProvider database) {
    final backupService = SqliteBackupService(provider: database);
    return SettingsRoutes(
      settingsRepository: SettingsSqliteRepository(provider: database),
      backupController: BackupController(
        exportBackupUseCase: ExportBackupUseCase(service: backupService),
        inspectBackupUseCase: InspectBackupUseCase(service: backupService),
        restoreBackupUseCase: RestoreBackupUseCase(service: backupService),
      ),
    );
  }

  final ISettingsRepositoryPort settingsRepository;
  final BackupController? backupController;

  /// Tela de configurações locais.
  Route<void> edit() {
    return appScopedRoute<SettingsController, void>(
      create: (_) => SettingsController(
        getSettings: GetSettings(repository: settingsRepository),
        updateSetting: UpdateSetting(repository: settingsRepository),
      ),
      builder: (_, _) => SettingsPage(backupController: backupController),
    );
  }
}
