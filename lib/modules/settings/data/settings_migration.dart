// Migração SQLite de configurações locais (UC-07.01).
//
// SRP: definir schema key/value tipado das políticas locais.

import 'package:dnolib/sqlite/sqlite.dart';

/// Migrações das configurações locais.
abstract final class SettingsMigration {
  /// Nome da tabela de configurações.
  static const table = 'app_settings';

  /// Cria a migration v11 (configurações key/value).
  static Migration v11() => Migration(
    version: 11,
    scripts: const [
      '''
          CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at_utc TEXT NOT NULL
          )
          ''',
    ],
  );
}
