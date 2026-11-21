// Value Objects do perfil comercial (UC-01.05, INV-SEC-14).
//
// SRP: validar e normalizar dados do perfil comercial do técnico.
// Não persiste, não formata UI, não acessa I/O.
//
// Pattern: Value Objects com Result.Fail tipado.

import 'package:dnolib/brlib/brlib.dart';
import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

/// Nome comercial/fantasia do técnico.
final class CommercialName {
  const CommercialName._(this.value);

  /// Valor normalizado.
  final String value;

  /// Cria nome comercial validado.
  static IResult<CommercialName, ValidationError> tryCreate(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return const Failure(
        ValidationError(
          code: 'ERR_PERFIL_NOME_INVALIDO',
          message: 'Informe o nome comercial.',
        ),
      );
    }
    if (normalized.length > 80) {
      return const Failure(
        ValidationError(
          code: 'ERR_PERFIL_NOME_INVALIDO',
          message: 'Nome comercial muito longo.',
        ),
      );
    }
    return Success(CommercialName._(normalized));
  }

  @override
  String toString() => 'CommercialName(redacted)';
}

/// Número de WhatsApp/telefone BR.
final class WhatsAppNumber {
  const WhatsAppNumber._(this.digits);

  /// Dígitos normalizados.
  final String digits;

  /// Cria WhatsApp validado.
  static IResult<WhatsAppNumber, ValidationError> tryCreate(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (!PhoneBrValidator.hasValidShape(digits)) {
      return const Failure(
        ValidationError(
          code: 'ERR_PERFIL_WHATSAPP_INVALIDO',
          message: 'Informe um WhatsApp válido com DDD.',
        ),
      );
    }
    return Success(WhatsAppNumber._(digits));
  }

  @override
  String toString() => 'WhatsAppNumber(redacted)';
}

/// Perfil comercial do técnico.
final class TechnicianProfile {
  const TechnicianProfile._({
    required this.commercialName,
    required this.whatsapp,
    required this.logoPath,
  });

  /// Nome comercial.
  final CommercialName commercialName;

  /// WhatsApp.
  final WhatsAppNumber whatsapp;

  /// Caminho privado gerenciado do logo (opcional).
  final String? logoPath;

  /// Cria perfil validado.
  static IResult<TechnicianProfile, ValidationError> tryCreate({
    required String commercialName,
    required String whatsapp,
    String? logoPath,
  }) {
    final nameResult = CommercialName.tryCreate(commercialName);
    if (nameResult.isFailure) {
      return Failure(nameResult.getOrNullFailure()!);
    }
    final whatsappResult = WhatsAppNumber.tryCreate(whatsapp);
    if (whatsappResult.isFailure) {
      return Failure(whatsappResult.getOrNullFailure()!);
    }
    return Success(
      TechnicianProfile._(
        commercialName: nameResult.getOrNull()!,
        whatsapp: whatsappResult.getOrNull()!,
        logoPath: logoPath,
      ),
    );
  }

  @override
  String toString() => 'TechnicianProfile(redacted)';
}
