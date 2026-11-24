// Testes unitários para o motor de compilação PDF on-device (UC-05.01 / INV-05).

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/reports/.index.dart';

// Gera um PNG 1x1 válido em memória para teste
Uint8List _createTinyPng() {
  const base64Png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
  return base64Decode(base64Png);
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
    });
  });
}
