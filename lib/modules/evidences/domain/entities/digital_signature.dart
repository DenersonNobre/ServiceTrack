// Entidade de Assinatura Digital canônica (UC-04.04/04.08, INV-03, ADR-001).
//
// SRP: validar assinatura PNG, nome e documento opcional por política.
// Redige PII em toString; não serializa PII/imagem em toJson. Sem I/O.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../ports/evidence_failure_codes.dart';

/// Limite máximo em bytes decodificados da assinatura PNG (UC-04.04, C-05).
const int kMaxSignatureSizeBytes = 150 * 1024;

const List<int> _pngMagicBytes = <int>[137, 80, 78, 71, 13, 10, 26, 10];

/// Assinatura digital do recebedor (PII redigida, LGPD).
final class DigitalSignature {
  DigitalSignature._({
    required Uint8List signatureBytes,
    required this.signerName,
    required this.documentNumber,
    required this.signedAtUtc,
  }) : signatureBytes = Uint8List.fromList(signatureBytes);

  /// Imagem PNG rasterizada canônica.
  final Uint8List signatureBytes;

  /// Nome completo do recebedor (PII).
  final String signerName;

  /// Documento de identificação opcional por política (PII sensível, C-01/C-03).
  final String? documentNumber;

  /// Momento UTC da captura; null apenas para legado sem fabricação (C-04).
  final DateTime? signedAtUtc;

  /// Cria assinatura nova validada (INV-03, C-03/C-05/C-08/C-09).
  static IResult<DigitalSignature, ValidationError> tryCreate({
    required Uint8List signatureBytes,
    required String signerName,
    String? documentNumber,
    bool requireDocumentByPolicy = false,
    DateTime? signedAtUtc,
  }) {
    final pngResult = _validatePngBytes(signatureBytes);
    if (pngResult.isFailure) return Failure(pngResult.getOrNullFailure()!);

    final nameResult = _normalizeName(signerName);
    if (nameResult case Failure(:final value)) return Failure(value);
    final normalizedName = (nameResult as Success<String, ValidationError>).value;

    final docResult = _normalizeDocument(
      documentNumber,
      requireDocumentByPolicy: requireDocumentByPolicy,
    );
    if (docResult case Failure(:final value)) return Failure(value);
    final normalizedDoc =
        (docResult as Success<String?, ValidationError>).value;

    return Success(
      DigitalSignature._(
        signatureBytes: signatureBytes,
        signerName: normalizedName,
        documentNumber: normalizedDoc,
        signedAtUtc: (signedAtUtc ?? DateTime.now()).toUtc(),
      ),
    );
  }

  /// Reidrata assinatura persistida/legada sem fabricar metadados (C-04/C-05/C-08).
  static IResult<DigitalSignature, ValidationError> restore({
    required Uint8List signatureBytes,
    required String signerName,
    String? documentNumber,
    DateTime? signedAtUtc,
  }) {
    final pngResult = _validatePngBytes(signatureBytes);
    if (pngResult.isFailure) return Failure(pngResult.getOrNullFailure()!);

    final nameResult = _normalizeName(signerName);
    if (nameResult case Failure(:final value)) return Failure(value);
    final normalizedName = (nameResult as Success<String, ValidationError>).value;

    final rawDoc = documentNumber?.trim();
    final normalizedDoc =
        (rawDoc == null || rawDoc.isEmpty) ? null : rawDoc;
    if (normalizedDoc != null && normalizedDoc.length > 30) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.invalidSignerDocument,
          message: 'Documento do recebedor inválido.',
        ),
      );
    }

    return Success(
      DigitalSignature._(
        signatureBytes: signatureBytes,
        signerName: normalizedName,
        documentNumber: normalizedDoc,
        signedAtUtc: signedAtUtc?.toUtc(),
      ),
    );
  }

  /// Codec de borda para persistência/serialização (C-06).
  String toBase64() => base64Encode(signatureBytes);

  static IResult<void, ValidationError> _validatePngBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.missingSignature,
          message: 'Colha a assinatura do cliente na tela antes de confirmar.',
        ),
      );
    }
    if (bytes.length > kMaxSignatureSizeBytes) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.signatureSizeExceeded,
          message: 'Assinatura excedeu o limite máximo de 150 KB.',
        ),
      );
    }
    if (!_hasPngMagic(bytes)) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.invalidSignature,
          message: 'Assinatura inválida.',
        ),
      );
    }
    return const Success(null);
  }

  static bool _hasPngMagic(Uint8List bytes) {
    if (bytes.length < _pngMagicBytes.length) return false;
    for (var i = 0; i < _pngMagicBytes.length; i++) {
      if (bytes[i] != _pngMagicBytes[i]) return false;
    }
    return true;
  }

  static IResult<String, ValidationError> _normalizeName(String signerName) {
    final normalizedName = signerName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedName.isEmpty || normalizedName.length > 120) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.missingSignerName,
          message: 'Informe o nome completo de quem está assinando.',
        ),
      );
    }
    return Success(normalizedName);
  }

  static IResult<String?, ValidationError> _normalizeDocument(
    String? documentNumber, {
    required bool requireDocumentByPolicy,
  }) {
    final raw = documentNumber?.trim();
    final normalized = (raw == null || raw.isEmpty) ? null : raw;
    if (requireDocumentByPolicy && normalized == null) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.missingSignerDocument,
          message: 'Informe o documento do recebedor.',
        ),
      );
    }
    if (normalized != null && normalized.length > 30) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.invalidSignerDocument,
          message: 'Documento do recebedor inválido.',
        ),
      );
    }
    return Success(normalized);
  }

  /// Redigido para não vazar PII em logs (LGPD, C-06/C-07).
  @override
  String toString() =>
      'DigitalSignature(redacted, bytes=${signatureBytes.length}, hasDoc=${documentNumber != null}, hasSignedAt=${signedAtUtc != null})';
}
