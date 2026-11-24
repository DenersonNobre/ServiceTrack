// Teste unitário para ReportStorageAdapter (UC-05.04).
//
// Valida gravação, recuperação, verificação de existência e NFR de recuperação rápida (<100ms).

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/reports/data/report_storage_adapter.dart';
import 'package:service_track/modules/reports/domain/ports/report_failure_codes.dart';

void main() {
  late Directory tempDir;
  late ReportStorageAdapter adapter;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('report_storage_test_');
    adapter = ReportStorageAdapter(baseDirectoryPath: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('UC-05.04 - ReportStorageAdapter', () {
    final samplePdfBytes = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52]); // %PDF-1.4

    test('hasSavedReport retorna false quando nenhum laudo foi salvo', () async {
      final exists = await adapter.hasSavedReport('OS-999');
      expect(exists, isFalse);
    });

    test('saveReport salva em reports/OS-<workOrderId>.pdf e hasSavedReport passa a retornar true', () async {
      final saveResult = await adapter.saveReport(
        workOrderId: 'OS-1001',
        bytes: samplePdfBytes,
      );

      expect(saveResult.isSuccess, isTrue);
      final savedPath = saveResult.getOrNull()!;
      expect(savedPath, contains('reports'));
      expect(savedPath, endsWith('OS-1001.pdf'));

      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), equals(samplePdfBytes));

      final exists = await adapter.hasSavedReport('OS-1001');
      expect(exists, isTrue);
    });

    test('getSavedReport recupera bytes idênticos do arquivo salvo e respeita NFR < 100ms', () async {
      await adapter.saveReport(
        workOrderId: 'OS-2002',
        bytes: samplePdfBytes,
      );

      final stopwatch = Stopwatch()..start();
      final getResult = await adapter.getSavedReport('OS-2002');
      stopwatch.stop();

      expect(getResult.isSuccess, isTrue);
      expect(getResult.getOrNull(), equals(samplePdfBytes));
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Acesso a laudo em cache local deve ser < 100ms');
    });

    test('getSavedReport retorna Failure quando arquivo não existe', () async {
      final result = await adapter.getSavedReport('OS-NAO-EXISTE');
      expect(result.isFailure, isTrue);
      final failure = result.getOrNullFailure()!;
      expect(failure.code, ReportFailureCodes.reportNotFound);
    });

    test('saveReport com workOrderId vazio retorna Failure sem gravar', () async {
      final result = await adapter.saveReport(
        workOrderId: '   ',
        bytes: samplePdfBytes,
      );
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, ReportFailureCodes.invalidReportFileName);
    });

    test('getSavedReport com workOrderId vazio retorna Failure', () async {
      final result = await adapter.getSavedReport('');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, ReportFailureCodes.invalidReportFileName);
    });
  });
}
