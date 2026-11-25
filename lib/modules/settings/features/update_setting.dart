import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../domain/.index.dart';

/// Caso de uso de atualização de uma política tipada.
final class UpdateSetting {
  const UpdateSetting({required this.repository});

  /// Porta de persistência.
  final ISettingsRepositoryPort repository;

  /// Valida a chave contra o catálogo e persiste o novo valor.
  Future<IResult<SettingsSnapshot, ValidationError>> execute({
    required String key,
    required Object value,
  }) async {
    final settingKey = SettingKey.fromStorageKey(key);
    if (settingKey == null) {
      return const Failure(
        ValidationError(
          code: SettingsFailureCodes.invalidKey,
          message: 'Configuração inválida.',
        ),
      );
    }
    return repository.update(settingKey, value);
  }
}
