import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../domain/.index.dart';

/// Implementação em memória de [ISettingsRepositoryPort] (testes/fallback).
final class MemorySettingsRepository implements ISettingsRepositoryPort {
  /// Cria com [initial] ou defaults seguros.
  MemorySettingsRepository([SettingsSnapshot? initial])
    : _snapshot = initial ?? SettingsSnapshot.defaults();

  SettingsSnapshot _snapshot;

  @override
  Future<IResult<SettingsSnapshot, ValidationError>> load() async =>
      Success(_snapshot);

  @override
  Future<IResult<SettingsSnapshot, ValidationError>> update(
    SettingKey key,
    Object value,
  ) async {
    _snapshot = _snapshot.withValue(key, value);
    return Success(_snapshot);
  }
}
