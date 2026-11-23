// Senha mestre local do técnico (UC-01.01).
//
// SRP: garante comprimento mínimo da senha que protege o cofre local.
// NÃO aplica hash, NÃO persiste, NÃO toca em UI.
// Pattern: Value Object com Result (dnolib IResult/ValidationError).
//
// Dependências: dnolib (core/patterns).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../ports/auth_failure_codes.dart';

/// Senha mestre em claro (hash fica na camada de persistência).
/// Criar apenas via [tryCreate].
final class MasterPassword {
  const MasterPassword._(this.value);

  /// Valor original (sem normalização: espaço pode ser intencional).
  final String value;

  /// Comprimento mínimo aceito.
  static const minLength = 8;

  /// Valida [raw] e devolve sucesso ou falha tipada.
  static IResult<MasterPassword, ValidationError> tryCreate(String? raw) {
    final candidate = raw ?? '';
    if (candidate.length < minLength) {
      return const Failure(
        ValidationError(
          code: AuthFailureCodes.passwordTooShort,
          message: 'A senha deve ter ao menos 8 caracteres.',
        ),
      );
    }
    return Success(MasterPassword._(candidate));
  }

  /// Redigido de propósito: senha jamais aparece em log (INV-SEC-06).
  @override
  String toString() => 'MasterPassword(redacted)';
}
