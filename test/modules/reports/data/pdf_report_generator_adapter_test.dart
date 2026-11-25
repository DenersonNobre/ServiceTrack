// Testes unitários para o motor de compilação PDF on-device (UC-05.01 / INV-05).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/reports/.index.dart';

// Gera um PNG 1x1 válido em memória para teste
Uint8List _createTinyPng() {
  const base64Png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
  return base64Decode(base64Png);
}

/// Extrai texto legível dos streams do PDF (FlateDecode/zlib + latin1).
///
/// Heurística para asserções de conteúdo: infla streams, extrai literais de
/// texto PDF `(...)` (incluindo fragmentos de TJ) e junta em texto plano,
/// além de manter o conteúdo bruto inflado como fallback.
String extractPdfReadableText(Uint8List pdfBytes) {
  final raw = latin1.decode(pdfBytes, allowInvalid: true);
  final buffer = StringBuffer();
  final streamRegex = RegExp(r'stream\r?\n(.*?)endstream', dotAll: true);
  final paren = RegExp(r'\((?:\\.|[^\\()])*\)');

  for (final match in streamRegex.allMatches(raw)) {
    final streamContent = match.group(1) ?? '';
    final streamBytes = latin1.encode(streamContent);
    String text;
    try {
      final inflated = zlib.decode(streamBytes);
      text = latin1.decode(inflated, allowInvalid: true);
    } catch (_) {
      // Stream não comprimido ou filtro não-zlib: usa conteúdo bruto.
      text = latin1.decode(streamBytes, allowInvalid: true);
    }
    buffer.writeln(text);
    final plain = StringBuffer();
    for (final m in paren.allMatches(text)) {
      var token = m.group(0)!;
      if (token.length >= 2) token = token.substring(1, token.length - 1);
      token = token
          .replaceAll(r'\(', '(')
          .replaceAll(r'\)', ')')
          .replaceAll(r'\\', r'\');
      plain.write(token);
      plain.write(' ');
    }
    buffer.writeln(plain.toString());
  }

  // Fallback: inclui o conteúdo bruto para capturar texto fora de streams.
  buffer.writeln(raw);
  return buffer.toString();
}

void expectPdfContainsAll(String pdfText, List<String> expectedParts) {
  for (final part in expectedParts) {
    expect(pdfText, contains(part), reason: 'PDF deveria conter: "$part"');
  }
}

void main() {
  const generator = PdfReportGeneratorAdapter();
  final samplePng = _createTinyPng();

  group('UC-05.01 - PdfReportGeneratorAdapter (Motor de PDF on-device)', () {
    test('Rejeita compilação de OS que não esteja com status COMPLETED', () async {
      const data = ReportData(
        workOrderId: 'wo-1',
        status: 'SCHEDULED',
        serviceDescription: 'Manutenção preventiva em ar-condicionado',
        scheduledDateFormatted: '24/11/2026',
      );

      final result = await generator.generatePdf(data);

      expect(result.isFailure, isTrue);
      final failure = result.getOrNullFailure()!;
      expect(failure.code, ReportFailureCodes.workOrderNotCompleted);
    });

    test('Gera PDF válido (%PDF-) para OS COMPLETED sem fotos', () async {
      final data = ReportData(
        workOrderId: 'wo-2',
        status: 'COMPLETED',
        serviceDescription: 'Troca de capacitor e carga de gás R410A',
        scheduledDateFormatted: '24/11/2026 09:00',
        completedDateFormatted: '24/11/2026 11:30',
        technicianName: 'Carlos Silva',
        technicianCommercialName: 'ClimaFrio Refrigeração',
        technicianPhone: '(11) 98888-7777',
        customerName: 'Padaria Estrela',
        customerDocument: '12.345.678/0001-90',
        customerPhone: '(11) 97777-6666',
        locationAddress: 'Rua das Flores, 123 - Centro',
        estimatedAmountFormatted: 'R\$ 450,00',
        checklistItems: const [
          ReportChecklistItem(
            title: 'Verificar pressão da linha de sucção',
            statusDescription: 'Conforme',
            notes: 'Pressão nominal estabilizada',
          ),
          ReportChecklistItem(
            title: 'Limpeza dos filtros de ar',
            statusDescription: 'Conforme',
          ),
        ],
        signaturePngBytes: samplePng,
        signerName: 'João da Silva',
        signerDocument: '123.456.789-00',
        checkInGpsFormatted: '-23.5505, -46.6333',
        checkOutGpsFormatted: '-23.5506, -46.6334',
      );

      final result = await generator.generatePdf(data);

      expect(result.isSuccess, isTrue);
      final bytes = result.getOrNull()!;
      expect(bytes.length, greaterThan(100));

      // Valida assinatura mágica de arquivo PDF: %PDF-
      final header = ascii.decode(bytes.sublist(0, 5));
      expect(header, '%PDF-');

      final pdfText = extractPdfReadableText(bytes);
      expectPdfContainsAll(pdfText, [
        'Laudo',
        'Atendimento',
        'OS #wo-2',
        'DADOS DO CLIENTE',
        'Padaria Estrela',
        'DETALHES DO ATENDIMENTO',
        'Data Agendada:',
        'Conclus',
        '24/11/2026 11:30',
        'Valor do Servi',
        'R\$ 450,00',
        'Check-in GPS:',
        '-23.5505, -46.6333',
        'Check-out GPS:',
        '-23.5506, -46.6334',
        'DESCRI',
        'EXECUTADOS',
        'Troca de capacitor',
        'CHECKLIST',
        'CONFORMIDADE',
        'Verificar press',
        'Conforme',
        'Limpeza dos filtros',
        'Assinatura do T',
        'Carlos Silva',
        'Recebedor:',
        'da Silva',
      ]);
    });

    test('Gera PDF válido (%PDF-) com 6 fotos e respeita NFR < 2000ms', () async {
      final photos = List.generate(
        6,
        (i) => ReportPhotoEvidence(
          bytes: samplePng,
          caption: 'Foto ${i + 1}',
          timestampFormatted: '24/11/2026 10:1$i',
        ),
      );

      final data = ReportData(
        workOrderId: 'wo-3',
        status: 'COMPLETED',
        serviceDescription: 'Instalação completa de chiller industrial com 6 evidências fotográficas',
        scheduledDateFormatted: '24/11/2026 08:00',
        completedDateFormatted: '24/11/2026 14:00',
        technicianName: 'Marcos Eletricista',
        technicianCommercialName: 'EletroService',
        customerName: 'Indústria ABC',
        checklistItems: const [
          ReportChecklistItem(title: 'Disjuntor instalado', statusDescription: 'Conforme'),
          ReportChecklistItem(title: 'Aterramento testado', statusDescription: 'Conforme'),
        ],
        photos: photos,
        signaturePngBytes: samplePng,
        signerName: 'Diretor Roberto',
      );

      final stopwatch = Stopwatch()..start();
      final result = await generator.generatePdf(data);
      stopwatch.stop();

      expect(result.isSuccess, isTrue);
      final bytes = result.getOrNull()!;
      expect(bytes.length, greaterThan(500));

      final header = ascii.decode(bytes.sublist(0, 5));
      expect(header, '%PDF-');

      // NFR INV-05: menos de 2000ms
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));

      final pdfText = extractPdfReadableText(bytes);
      expectPdfContainsAll(pdfText, [
        'Laudo',
        'Atendimento',
        'OS #wo-3',
        'Ind',
        'ABC',
        'Marcos Eletricista',
        'EletroService',
        'chiller industrial',
        'CHECKLIST',
        'Disjuntor instalado',
        'Aterramento testado',
        'Conforme',
        'EVID',
        'FOTOGR',
        'Assinatura do T',
        'Recebedor:',
        'Diretor Roberto',
        '24/11/2026 14:00',
      ]);
    });
  });
}
