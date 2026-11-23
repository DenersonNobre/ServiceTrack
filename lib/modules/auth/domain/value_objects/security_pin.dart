// PIN numérico de desbloqueio rápido (UC-01.01).
//
// SRP: garante PIN com 4 a 6 dígitos para o teclado de campo.
// NÃO aplica hash, NÃO persiste, NÃO toca em UI.
// Pattern: Value Object com Result (dnolib IResult/ValidationError).
//
// Dependências: dnolib (core/patterns).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../ports/auth_failure_codes.dart';

/// PIN de desbloqueio. Criar apenas via [tryCreate].
final class SecurityPin {
  const SecurityPin._(this.value);

  /// Dígitos do PIN.
  final String value;

  static final _shape = RegExp(r'^\d{4,6}$');

  /// Valida [raw] e devolve sucesso ou falha tipada.
  static IResult<SecurityPin, ValidationError> tryCreate(String? raw) {
    final candidate = raw ?? '';
    if (!_shape.hasMatch(candidate)) {
      return const Failure(
        ValidationError(
          code: AuthFailureCodes.invalidPin,
          message: 'O PIN deve ter de 4 a 6 dígitos numéricos.',
        ),
      );
    }
    return Success(SecurityPin._(candidate));
  }

  /// Redigido de propósito: PIN jamais aparece em log (INV-SEC-06).
  @override
  String toString() => 'SecurityPin(redacted)';
}
