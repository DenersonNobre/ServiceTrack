import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/evidences/.index.dart';

void main() {
  group('UC-04.04 - DigitalSignature (INV-03)', () {
    test('aceita assinatura valida com nome e documento', () {
      final result = DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList([137, 80, 78, 71]),
        signerName: 'Carlos Eduardo',
        documentNumber: '12345678909',
      );
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()?.signerName, 'Carlos Eduardo');
      expect(result.getOrNull().toString(), contains('redacted'));
    });

    test('rejeita assinatura vazia com ERR_ASSINATURA_AUSENTE', () {
      final result = DigitalSignature.tryCreate(
        signatureBytes: Uint8List(0),
        signerName: 'Carlos Eduardo',
        documentNumber: '12345678909',
      );
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, 'ERR_ASSINATURA_AUSENTE');
    });

    test('rejeita nome vazio com ERR_ASSINANTE_NOME_OBRIGATORIO', () {
      final result = DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList([137, 80, 78, 71]),
        signerName: '   ',
        documentNumber: '12345678909',
      );
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, 'ERR_ASSINANTE_NOME_OBRIGATORIO');
    });

    test('rejeita assinatura > 150 KB com ERR_ASSINATURA_TAMANHO_EXCEDIDO', () {
      final result = DigitalSignature.tryCreate(
        signatureBytes: Uint8List(kMaxSignatureSizeBytes + 1),
        signerName: 'Carlos Eduardo',
        documentNumber: '12345678909',
      );
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, 'ERR_ASSINATURA_TAMANHO_EXCEDIDO');
    });
  });
}
