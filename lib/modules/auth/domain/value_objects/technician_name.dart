// Nome profissional do técnico no onboarding (UC-01.01).
//
// SRP: valida e carrega o nome exibido no cabeçalho dos laudos.
// NÃO persiste, NÃO formata documento, NÃO toca em UI.
// Pattern: Value Object com Result (dnolib IResult/ValidationError).
//
// Dependências: dnolib (core/patterns).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../ports/auth_failure_codes.dart';

/// Nome do técnico. Criar apenas via [tryCreate].
final class TechnicianName {
  const TechnicianName._(this.value);

  /// Nome já aparado.
  final String value;

  /// Valida [raw] e devolve sucesso ou falha tipada.
  static IResult<TechnicianName, ValidationError> tryCreate(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.length < 2) {
      return const Failure(
        ValidationError(
          code: AuthFailureCodes.nameRequired,
          message: 'Informe o nome do técnico.',
        ),
      );
    }
    return Success(TechnicianName._(trimmed));
  }
}
