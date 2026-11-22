import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../domain/.index.dart';

/// Caso de uso de leitura das configurações locais.
final class GetSettings {
  const GetSettings({required this.repository});

  /// Porta de persistência.
  final ISettingsRepositoryPort repository;

  /// Carrega o snapshot vigente com defaults seguros.
  Future<IResult<SettingsSnapshot, ValidationError>> execute() =>
      repository.load();
}
