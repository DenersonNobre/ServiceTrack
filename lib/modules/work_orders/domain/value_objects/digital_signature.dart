// Value Object Assinatura Digital (UC-03.05, INV-SEC-24/25).
//
// SRP: validar assinatura/recebedor e proteger PII por redação.
// Não persiste, não renderiza UI.

import 'dart:convert';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

/// Assinatura digital do recebedor (PII redigida).
final class DigitalSignature {
  const DigitalSignature._({required this.signerName, required this.imageBase64});

  static const int maxSignerNameLength = 120;
  static const int maxImageBase64Length = 200000; // ~150KB binário

  /// Nome do recebedor (PII - não expor em logs).
  final String signerName;

  /// Imagem raster da assinatura em base64 (sensível - não expor).
  final String imageBase64;

  static IResult<DigitalSignature, ValidationError> tryCreate({
    required String signerName,
    required String imageBase64,
  }) {
    final name = signerName.trim();
    if (name.isEmpty || name.length > maxSignerNameLength) {
      return const Failure(ValidationError(
        code: 'ERR_ASSINATURA_INVALIDA',
        message: 'Nome do recebedor inválido.',
      ));
    }
    final img = imageBase64.trim();
    if (img.isEmpty || img.length > maxImageBase64Length) {
      return const Failure(ValidationError(
        code: 'ERR_ASSINATURA_INVALIDA',
        message: 'Assinatura inválida.',
      ));
    }
    try {
      final bytes = base64Decode(img);
      if (bytes.isEmpty) {
        return const Failure(ValidationError(
          code: 'ERR_ASSINATURA_INVALIDA',
          message: 'Assinatura inválida.',
        ));
      }
    } catch (_) {
      return const Failure(ValidationError(
        code: 'ERR_ASSINATURA_INVALIDA',
        message: 'Assinatura inválida.',
      ));
    }
    return Success(DigitalSignature._(signerName: name, imageBase64: img));
  }

  @override
  String toString() => 'DigitalSignature(redacted)';
}
