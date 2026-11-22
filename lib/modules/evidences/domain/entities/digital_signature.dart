// Entidade de Assinatura Digital do cliente (UC-04.04 / INV-03).
//
// SRP: validar bytes PNG da assinatura (<= 150 KB), nome e documento do signatário.

import 'dart:typed_data';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

/// Limite máximo em bytes da assinatura rasterizada em PNG (UC-04.04).
const int kMaxSignatureSizeBytes = 150 * 1024;

/// Assinatura digital coletada na tela do dispositivo.
final class DigitalSignature {
  DigitalSignature._({
    required Uint8List signatureBytes,
    required this.signerName,
    required this.documentNumber,
    required this.signedAtUtc,
  }) : signatureBytes = Uint8List.fromList(signatureBytes);

  /// Imagem PNG rasterizada do traço da assinatura.
  final Uint8List signatureBytes;

  /// Nome completo do recebedor/cliente.
  final String signerName;

  /// Documento de identificação (CPF ou RG normalizado).
  final String documentNumber;

  /// Momento UTC da assinatura.
  final DateTime signedAtUtc;

  /// Cria uma assinatura digital validada (INV-03).
  static IResult<DigitalSignature, ValidationError> tryCreate({
    required Uint8List signatureBytes,
    required String signerName,
    required String documentNumber,
    DateTime? signedAtUtc,
  }) {
    if (signatureBytes.isEmpty) {
      return const Failure(
        ValidationError(
          code: 'ERR_ASSINATURA_AUSENTE',
          message: 'Colha a assinatura do cliente na tela antes de confirmar.',
        ),
      );
    }
    if (signatureBytes.length > kMaxSignatureSizeBytes) {
      return const Failure(
        ValidationError(
          code: 'ERR_ASSINATURA_TAMANHO_EXCEDIDO',
          message: 'Assinatura excedeu o limite máximo de 150 KB.',
        ),
      );
    }
    final normalizedName = signerName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedName.isEmpty || normalizedName.length > 120) {
      return const Failure(
        ValidationError(
          code: 'ERR_ASSINANTE_NOME_OBRIGATORIO',
          message: 'Informe o nome completo de quem está assinando.',
        ),
      );
    }
    final normalizedDoc = documentNumber.trim();
    if (normalizedDoc.isEmpty || normalizedDoc.length > 30) {
      return const Failure(
        ValidationError(
          code: 'ERR_ASSINANTE_DOCUMENTO_OBRIGATORIO',
          message: 'Informe o CPF ou RG do recebedor.',
        ),
      );
    }
    return Success(
      DigitalSignature._(
        signatureBytes: signatureBytes,
        signerName: normalizedName,
        documentNumber: normalizedDoc,
        signedAtUtc: (signedAtUtc ?? DateTime.now()).toUtc(),
      ),
    );
  }

  /// Redigido para não vazar PII em logs (LGPD).
  @override
  String toString() => 'DigitalSignature(redacted, bytes=${signatureBytes.length})';
}
