import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:dnolib/sqlite/sqlite.dart';

import '../domain/.index.dart';
import 'settings_migration.dart';

/// Adapter SQLite da porta [ISettingsRepositoryPort].
final class SettingsSqliteRepository implements ISettingsRepositoryPort {
  /// Cria o repositório sobre [provider].
  SettingsSqliteRepository({required this.provider});

  /// Provider SQLite da `dnolib`.
  final SqliteProvider provider;

  @override
  Future<IResult<SettingsSnapshot, ValidationError>> load() async {
    try {
      final db = await provider.db;
      final rows = await db.query(SettingsMigration.table);
      final values = <SettingKey, bool>{};

      for (final row in rows) {
        final rawKey = row['key'];
        if (rawKey is! String) continue;

        final key = SettingKey.fromStorageKey(rawKey);
        if (key == null) continue;

        final rawValue = row['value'];
        if (rawValue == 'true') {
          values[key] = true;
          continue;
        }
        if (rawValue == 'false') {
          values[key] = false;
          continue;
        }
        return const Failure(
          ValidationError(
            code: SettingsFailureCodes.invalidValue,
            message: 'Valor de configuração inválido.',
          ),
        );
      }

      return Success(SettingsSnapshot(values));
    } on Exception {
      return const Failure(
        ValidationError(
          code: SettingsFailureCodes.persistence,
          message: 'Não foi possível carregar as configurações.',
        ),
      );
    }
  }

  @override
  Future<IResult<SettingsSnapshot, ValidationError>> update(
    SettingKey key,
    bool value,
  ) async {
    try {
      final db = await provider.db;
      await db.execute(
        '''
        INSERT INTO ${SettingsMigration.table} (key, value, updated_at_utc)
        VALUES (?, ?, ?)
        ON CONFLICT(key) DO UPDATE SET
          value = excluded.value,
          updated_at_utc = excluded.updated_at_utc
        ''',
        [
          key.storageKey,
          value.toString(),
          DateTime.now().toUtc().toIso8601String(),
        ],
      );
      return await load();
    } on Exception {
      return const Failure(
        ValidationError(
          code: SettingsFailureCodes.persistence,
          message: 'Não foi possível salvar a configuração.',
        ),
      );
    }
  }
}
