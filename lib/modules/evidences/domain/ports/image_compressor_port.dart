// Porta de compressão de imagens on-device (DIP / UC-04.03).

import 'dart:typed_data';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

/// Contrato para compressão de fotos antes de salvar em disco.
abstract interface class IImageCompressorPort {
  /// Comprime [rawBytes] para JPEG respeitando [maxWidth], [quality] e
  /// aplicando marca d'água opcional de auditoria ([watermarkText]).
  Future<IResult<Uint8List, ValidationError>> compress(
    Uint8List rawBytes, {
    int maxWidth = 1920,
    int quality = 80,
    String? watermarkText,
  });
}
