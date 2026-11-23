// Adaptador de compressão de fotos em Isolate.run (UC-04.03 / RNF-03).
//
// SRP: decodificar, redimensionar (sem EXIF) e codificar JPEG fora da UI.

import 'dart:isolate';
import 'dart:typed_data';

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:image/image.dart' as img;

import '../domain/entities/photo_evidence.dart';
import '../domain/ports/evidence_failure_codes.dart';
import '../domain/ports/image_compressor_port.dart';

/// Implementação on-device de [IImageCompressorPort] usando `package:image`.
final class ImageCompressorAdapter implements IImageCompressorPort {
  /// Cria o adaptador.
  const ImageCompressorAdapter();

  @override
  Future<IResult<Uint8List, ValidationError>> compress(
    Uint8List rawBytes, {
    int maxWidth = 1920,
    int quality = 80,
    String? watermarkText,
  }) async {
    if (rawBytes.isEmpty) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.emptyImage,
          message: 'Arquivo de imagem vazio.',
        ),
      );
    }
    try {
      final compressed = await Isolate.run(
        () => _compressSync(
          rawBytes,
          maxWidth: maxWidth,
          quality: quality,
          watermarkText: watermarkText,
        ),
      );
      if (compressed == null) {
        return const Failure(
          ValidationError(
            code: EvidenceFailureCodes.invalidImage,
            message: 'Não foi possível decodificar a imagem.',
          ),
        );
      }
      if (compressed.length > kMaxPhotoSizeBytes) {
        return const Failure(
          ValidationError(
            code: EvidenceFailureCodes.invalidEvidenceSize,
            message: 'Imagem comprimida excedeu o limite de 400 KB.',
          ),
        );
      }
      return Success(compressed);
    } on Exception {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.imageCompressionFailed,
          message: 'Falha ao comprimir a imagem.',
        ),
      );
    }
  }

  static Uint8List? _compressSync(
    Uint8List rawBytes, {
    required int maxWidth,
    required int quality,
    String? watermarkText,
  }) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return null;
    final resized = decoded.width > maxWidth
        ? img.copyResize(decoded, width: maxWidth)
        : decoded;
    if (watermarkText != null && watermarkText.trim().isNotEmpty) {
      img.drawString(
        resized,
        watermarkText.trim(),
        font: img.arial14,
        x: 12,
        y: (resized.height - 26).clamp(4, resized.height),
        color: img.ColorRgb8(255, 255, 255),
      );
    }
    // encodeJpg gera novo JPEG limpo sem metadados EXIF originais.
    var q = quality.clamp(30, 95);
    var encoded = Uint8List.fromList(img.encodeJpg(resized, quality: q));
    while (encoded.length > kMaxPhotoSizeBytes && q > 30) {
      q = (q - 15).clamp(30, 95);
      encoded = Uint8List.fromList(img.encodeJpg(resized, quality: q));
    }
    return encoded;
  }
}
