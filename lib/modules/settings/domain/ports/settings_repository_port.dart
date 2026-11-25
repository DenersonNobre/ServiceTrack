import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../entities/.index.dart';
import '../value_objects/.index.dart';

/// Contrato de persistência das configurações locais (DIP).
abstract interface class ISettingsRepositoryPort {
  /// Carrega o snapshot, preenchendo defaults para chaves ausentes.
  Future<IResult<SettingsSnapshot, ValidationError>> load();

  /// Persiste uma política tipada e retorna o snapshot atualizado.
  Future<IResult<SettingsSnapshot, ValidationError>> update(
    SettingKey key,
    Object value,
  );
}
