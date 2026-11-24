// Teste unitário para o ShareServiceAdapter (UC-05.03).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/reports/data/share_service_adapter.dart';
import 'package:service_track/modules/reports/domain/ports/report_failure_codes.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  group('UC-05.03 - ShareServiceAdapter', () {
    test('Retorna erro quando caminho é vazio', () async {
      const adapter = ShareServiceAdapter();
      final result = await adapter.sharePdfFile(
        filePath: '   ',
        title: 'Laudo Técnico',
      );

      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, ReportFailureCodes.invalidReportFileName);
    });

    test('Retorna erro quando arquivo não existe no sistema de arquivos', () async {
      const adapter = ShareServiceAdapter();
      final result = await adapter.sharePdfFile(
        filePath: '/caminho/inexistente/laudo_teste.pdf',
        title: 'Laudo Técnico',
      );

      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, ReportFailureCodes.invalidReportFileName);
    });

    test('Compartilha com sucesso quando arquivo existe', () async {
      final tempDir = Directory.systemTemp.createTempSync('share_test');
      final tempFile = File('${tempDir.path}/laudo_valido.pdf')..writeAsStringSync('dummy pdf');

      List<XFile>? capturedFiles;
      String? capturedText;
      String? capturedSubject;

      final adapter = ShareServiceAdapter(
        shareInvoker: (files, {subject, text}) async {
          capturedFiles = files;
          capturedText = text;
          capturedSubject = subject;
        },
      );

      final result = await adapter.sharePdfFile(
        filePath: tempFile.path,
        title: 'Laudo OS-999',
        subject: 'Laudo Técnico OS-999',
      );

      expect(result.isSuccess, isTrue);
      expect(capturedFiles, isNotNull);
      expect(capturedFiles!.length, 1);
      expect(capturedFiles!.first.path, tempFile.path);
      expect(capturedText, 'Laudo OS-999');
      expect(capturedSubject, 'Laudo Técnico OS-999');

      tempDir.deleteSync(recursive: true);
    });
  });
}
