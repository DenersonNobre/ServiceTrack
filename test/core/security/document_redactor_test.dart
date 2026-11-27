import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/core/security/document_redactor.dart';

void main() {
  group('DocumentRedactor', () {
    test('retorna string vazia para entrada nula ou vazia', () {
      expect(DocumentRedactor.redact(null), '');
      expect(DocumentRedactor.redact(''), '');
      expect(DocumentRedactor.redact('   '), '');
    });

    test('mascara CPF de 11 dígitos formatado ou não formatado', () {
      // Formato exigido: ***.456.789-** (oculta os 3 primeiros e 2 dígitos verificadores)
      expect(DocumentRedactor.redact('12345678901'), '***.456.789-**');
      expect(DocumentRedactor.redact('123.456.789-01'), '***.456.789-**');
      expect(DocumentRedactor.redact('98765432100'), '***.654.321-**');
    });

    test('mascara CNPJ de 14 dígitos formatado ou não formatado', () {
      // Formato exigido: **.345.678/0001-** (oculta os 2 primeiros e 2 dígitos verificadores)
      expect(DocumentRedactor.redact('12345678000199'), '**.345.678/0001-**');
      expect(DocumentRedactor.redact('12.345.678/0001-99'), '**.345.678/0001-**');
    });

    test('mascara outros formatos / alfanuméricos preservando parte central', () {
      // RG ou identificador alfanumérico genérico
      // String curta: se <= 4 caracteres, oculta tudo com asteriscos
      expect(DocumentRedactor.redact('1234'), '****');
      expect(DocumentRedactor.redact('12'), '**');
      
      // String com mais de 4 caracteres: oculta prefixo e sufixo
      // Ex: RG 'MG1234567' -> '***345***' ou formato com asteriscos início e fim
      final redacted = DocumentRedactor.redact('MG1234567');
      expect(redacted.startsWith('**'), isTrue);
      expect(redacted.endsWith('**'), isTrue);
      expect(redacted.contains('1234567'), isFalse);
    });
  });
}
