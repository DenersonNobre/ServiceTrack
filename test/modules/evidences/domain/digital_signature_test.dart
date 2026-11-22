import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/evidences/.index.dart';

void main() {
  group('UC-04.04 - DigitalSignature (INV-03)', () {
    test('aceita assinatura valida com nome e documento', () {
      final result = DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
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
        signatureBytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
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

    test('C-08: rejeita bytes sem magic PNG com ERR_ASSINATURA_INVALIDA', () {
      final result = DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8]),
        signerName: 'Carlos Eduardo',
      );
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, 'ERR_ASSINATURA_INVALIDA');
    });

    test('C-03: documento opcional por padrão (minimização)', () {
      final result = DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        signerName: 'Carlos Eduardo',
      );
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()!.documentNumber, isNull);
    });

    test('C-03: documento obrigatório quando política exige', () {
      final result = DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        signerName: 'Carlos Eduardo',
        requireDocumentByPolicy: true,
      );
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, 'ERR_ASSINANTE_DOCUMENTO_OBRIGATORIO');
    });

    test('C-04: restore não fabrica signedAtUtc legado', () {
      final result = DigitalSignature.restore(
        signatureBytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        signerName: 'Carlos Eduardo',
      );
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()!.signedAtUtc, isNull);
    });

    test('C-06/C-07: toString redige PII e não expõe nome/doc/base64', () {
      final sig = DigitalSignature.tryCreate(
        signatureBytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        signerName: 'Maria Secreta',
        documentNumber: '12345678909',
      ).getOrNull()!;
      final s = sig.toString();
      expect(s, contains('redacted'));
      expect(s, isNot(contains('Maria')));
      expect(s, isNot(contains('12345678909')));
      expect(s, isNot(contains('iVBOR'))); // base64 prefix
    });
  });
}
