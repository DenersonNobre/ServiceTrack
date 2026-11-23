// E-mail de contato do técnico no onboarding (UC-01.01).
//
// SRP: valida formato e normaliza (trim + minúsculas) o e-mail.
// NÃO verifica entrega, NÃO persiste, NÃO toca em UI.
// Pattern: Value Object com Result (kortex_lib IResult/ValidationError).
//
// Dependências: kortex_lib (core/patterns).

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';

import '../ports/auth_failure_codes.dart';

/// E-mail do técnico. Criar apenas via [tryCreate].
final class ContactEmail {
  const ContactEmail._(this.value);

  /// E-mail normalizado (aparado e em minúsculas).
  final String value;

  static final _shape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Valida [raw] e devolve sucesso ou falha tipada.
  static IResult<ContactEmail, ValidationError> tryCreate(String? raw) {
    final normalized = (raw?.trim() ?? '').toLowerCase();
    if (!_shape.hasMatch(normalized)) {
      return const Failure(
        ValidationError(
          code: AuthFailureCodes.invalidEmail,
          message: 'Informe um e-mail válido.',
        ),
      );
    }
    return Success(ContactEmail._(normalized));
  }
}
