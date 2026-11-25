import 'dart:developer' as developer;

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../domain/.index.dart';
import 'settings_migration.dart';

/// Adapter SQLite da porta [ISettingsRepositoryPort].
final class SettingsSqliteRepository implements ISettingsRepositoryPort {
  /// Cria o repositório sobre [provider].
  SettingsSqliteRepository({required this.provider});

  /// Provider SQLite do `kortex_lib`.
  final SqliteProvider provider;

  @override
  Future<IResult<SettingsSnapshot, ValidationError>> load() async {
    try {
      final db = await provider.db;
      final rows = await db.query(SettingsMigration.table);
      final values = <SettingKey, Object>{};

      for (final row in rows) {
        final rawKey = row['key'];
        if (rawKey is! String) continue;

        final key = SettingKey.fromStorageKey(rawKey);
        if (key == null) continue;

        final rawValue = row['value'];
        if (rawValue is! String) continue;

        // Trata booleanos
        if (key.defaultValue is bool) {
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

        // Trata inteiros
        if (key.defaultValue is int) {
          final parsed = int.tryParse(rawValue);
          if (parsed != null) {
            values[key] = parsed;
            continue;
          }
          return const Failure(
            ValidationError(
              code: SettingsFailureCodes.invalidValue,
              message: 'Valor de configuração inválido.',
            ),
          );
        }

        // Trata strings e outros tipos
        values[key] = rawValue;
      }

      return Success(SettingsSnapshot(values));
    } on Exception catch (e, s) {
      developer.log(
        'Falha ao carregar configurações do SQLite',
        name: 'SettingsSqliteRepository',
        error: e,
        stackTrace: s,
      );
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
    Object value,
  ) async {
    try {
      final db = await provider.db;
      await db.insert(
        SettingsMigration.table,
        {
          'key': key.storageKey,
          'value': value.toString(),
          'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return await load();
    } on Exception catch (e, s) {
      developer.log(
        'Falha ao salvar configuração ${key.storageKey} no SQLite',
        name: 'SettingsSqliteRepository',
        error: e,
        stackTrace: s,
      );
      return const Failure(
        ValidationError(
          code: SettingsFailureCodes.persistence,
          message: 'Não foi possível salvar a configuração.',
        ),
      );
    }
  }
}
