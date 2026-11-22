import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:service_track/modules/evidences/.index.dart';

void main() {
  group('UC-04.03 - PhotoEvidence & ImageCompressor (INV-04)', () {
    test('aceita primeira foto dentro do limite (0 existentes, 320 KB)', () {
      final result = PhotoEvidence.tryCreate(
        id: 'p1',
        workOrderId: 'os-1',
        filePath: '/app/evidences/p1.jpg',
        sizeBytes: 320 * 1024,
        existingCount: 0,
        latitude: -23.55052,
        longitude: -46.633308,
      );
      expect(result.isSuccess, isTrue);
    });

    test('rejeita 7a foto com ERR_EVIDENCIA_LIMITE_EXCEDIDO (INV-04)', () {
      final result = PhotoEvidence.tryCreate(
        id: 'p7',
        workOrderId: 'os-1',
        filePath: '/app/evidences/p7.jpg',
        sizeBytes: 250 * 1024,
        existingCount: 6,
      );
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, 'ERR_EVIDENCIA_LIMITE_EXCEDIDO');
    });

    test('aceita 6a foto no limite de fronteira (5 existentes, 399 KB)', () {
      final result = PhotoEvidence.tryCreate(
        id: 'p6',
        workOrderId: 'os-1',
        filePath: '/app/evidences/p6.jpg',
        sizeBytes: 399 * 1024,
        existingCount: 5,
      );
      expect(result.isSuccess, isTrue);
    });

    test('ImageCompressorAdapter comprime imagem em Isolate.run <= 400 KB', () async {
      final rawImg = img.Image(width: 800, height: 600);
      img.fill(rawImg, color: img.ColorRgb8(17, 94, 89));
      final pngBytes = Uint8List.fromList(img.encodePng(rawImg));

      const adapter = ImageCompressorAdapter();
      final result = await adapter.compress(
        pngBytes,
        maxWidth: 640,
        quality: 80,
        watermarkText: '2026-11-21T23:40Z | -23.55,-46.63',
      );

      expect(result.isSuccess, isTrue);
      final jpeg = result.getOrNull()!;
      expect(jpeg.length, greaterThan(0));
      expect(jpeg.length, lessThanOrEqualTo(kMaxPhotoSizeBytes));
      final outImg = img.decodeJpg(jpeg)!;
      expect(outImg.width, lessThanOrEqualTo(640));

      final emptyRes = await adapter.compress(Uint8List(0));
      expect(emptyRes.getOrNullFailure()?.code, 'ERR_IMAGEM_VAZIA');

      final invalidRes = await adapter.compress(Uint8List.fromList([1, 2, 3, 4]));
      expect(invalidRes.getOrNullFailure()?.code, 'ERR_IMAGEM_INVALIDA');
    });
  });
}
