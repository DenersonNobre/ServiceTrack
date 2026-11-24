// Testes unitários e de widget para UC-05.02 (Preview do Laudo) e UC-05.03 (Compartilhamento Nativo).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';
import 'package:service_track/modules/reports/domain/models/report_data.dart';
import 'package:service_track/modules/reports/domain/ports/pdf_report_generator_port.dart';
import 'package:service_track/modules/reports/domain/ports/report_failure_codes.dart';
import 'package:service_track/modules/reports/domain/ports/share_service_port.dart';
import 'package:service_track/modules/reports/ui/preview/report_preview_controller.dart';
import 'package:service_track/modules/reports/ui/preview/report_preview_page.dart';
import 'package:service_track/modules/reports/ui/reports_routes.dart';

final class FakePdfReportGenerator implements IPdfReportGeneratorPort {
  FakePdfReportGenerator({this.result});

  IResult<Uint8List, ValidationError>? result;
  int callCount = 0;

  @override
  Future<IResult<Uint8List, ValidationError>> generatePdf(ReportData data) async {
    callCount++;
    return result ?? Success(Uint8List.fromList([1, 2, 3, 4]));
  }
}

final class FakeShareService implements IShareServicePort {
  FakeShareService({this.result});

  IResult<void, ValidationError>? result;
  int shareCount = 0;
  String? lastSharedPath;
  String? lastTitle;

  @override
  Future<IResult<void, ValidationError>> sharePdfFile({
    required String filePath,
    required String title,
    String? subject,
  }) async {
    shareCount++;
    lastSharedPath = filePath;
    lastTitle = title;
    return result ?? const Success(null);
  }
}

void main() {
  const sampleData = ReportData(
    workOrderId: 'OS-1001',
    status: 'COMPLETED',
    serviceDescription: 'Troca de compressor e recarga de fluido',
    scheduledDateFormatted: '24/11/2026 09:00',
    completedDateFormatted: '24/11/2026 11:30',
    customerName: 'Supermercado Central',
    customerDocument: '12.345.678/0001-90',
    customerPhone: '(11) 98765-4321',
    locationAddress: 'Av. Paulista, 1000',
    technicianName: 'Pedro Técnico',
    estimatedAmountFormatted: 'R\$ 850,00',
  );

  group('UC-05.02 / UC-05.03 - ReportPreviewController (TDD)', () {
    test('Inicializa gerando PDF com sucesso e permite compartilhamento com 1 toque', () async {
      final fakeGenerator = FakePdfReportGenerator(
        result: Success(Uint8List.fromList([37, 80, 68, 70, 45])), // %PDF-
      );
      final fakeShare = FakeShareService();

      final controller = ReportPreviewController(
        reportData: sampleData,
        pdfGenerator: fakeGenerator,
        shareService: fakeShare,
        tempPathResolver: () async => '/tmp/laudo_OS-1001.pdf',
        fileSaver: (path, bytes) async {},
      );

      expect(controller.loading.value, isTrue);
      expect(controller.generatedBytes.value, isNull);
      expect(controller.filePath.value, isNull);
      expect(controller.errorMessage.value, isNull);

      await controller.generate();

      expect(fakeGenerator.callCount, 1);
      expect(controller.loading.value, isFalse);
      expect(controller.generatedBytes.value, isNotNull);
      expect(controller.filePath.value, '/tmp/laudo_OS-1001.pdf');
      expect(controller.errorMessage.value, isNull);

      // UC-05.03: Compartilhamento com 1 toque
      final shareResult = await controller.share();
      expect(shareResult, isTrue);
      expect(fakeShare.shareCount, 1);
      expect(fakeShare.lastSharedPath, '/tmp/laudo_OS-1001.pdf');
      expect(fakeShare.lastTitle, contains('OS-1001'));

      controller.dispose();
    });

    test('Trata erro ao gerar PDF e expõe mensagem amigável com retry', () async {
      final fakeGenerator = FakePdfReportGenerator(
        result: const Failure(
          ValidationError(
            code: ReportFailureCodes.pdfGenerationFailed,
            message: 'Falha ao processar fontes ou memória insuficiente.',
          ),
        ),
      );
      final fakeShare = FakeShareService();

      final controller = ReportPreviewController(
        reportData: sampleData,
        pdfGenerator: fakeGenerator,
        shareService: fakeShare,
        tempPathResolver: () async => '/tmp/laudo_retry.pdf',
        fileSaver: (path, bytes) async {},
      );

      await controller.generate();

      expect(controller.loading.value, isFalse);
      expect(controller.generatedBytes.value, isNull);
      expect(controller.errorMessage.value, isNotNull);
      expect(
        controller.errorMessage.value,
        'Falha ao processar fontes ou memória insuficiente.',
      );

      // Retry com sucesso
      fakeGenerator.result = Success(Uint8List.fromList([1, 2, 3]));
      await controller.generate();

      expect(controller.loading.value, isFalse);
      expect(controller.generatedBytes.value, isNotNull);
      expect(controller.errorMessage.value, isNull);

      controller.dispose();
    });
  });

  group('UC-05.02 / UC-05.03 - ReportPreviewPage & ReportsRoutes (Widget Test)', () {
    testWidgets('Exibe cabeçalho do laudo, CTA de compartilhar com min 48dp', (tester) async {
      final fakeGenerator = FakePdfReportGenerator(
        result: Success(Uint8List.fromList([37, 80, 68, 70, 45])),
      );
      final fakeShare = FakeShareService();

      final controller = ReportPreviewController(
        reportData: sampleData,
        pdfGenerator: fakeGenerator,
        shareService: fakeShare,
        tempPathResolver: () async => '/tmp/laudo_preview.pdf',
        fileSaver: (_, _) async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KortexScope(
            providers: [
              KortexProvider<ReportPreviewController>(
                create: (_) => controller,
                dispose: (c) => c.dispose(),
              ),
            ],
            child: const ReportPreviewPage(),
          ),
        ),
      );

      // Durante carregamento inicial
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Conteúdo do laudo
      expect(find.text('Laudo Técnico'), findsOneWidget);
      expect(find.text('OS #OS-1001'), findsOneWidget);
      expect(find.text('Supermercado Central'), findsOneWidget);
      expect(find.text('Troca de compressor e recarga de fluido'), findsOneWidget);

      // Botão CTA de Compartilhar
      final shareBtnFinder = find.widgetWithText(FilledButton, 'Compartilhar Laudo PDF');
      expect(shareBtnFinder, findsOneWidget);

      final shareSize = tester.getSize(shareBtnFinder);
      expect(shareSize.height, greaterThanOrEqualTo(48.0));
      expect(shareSize.width, greaterThanOrEqualTo(48.0));

      // Dispara compartilhamento ao tocar
      await tester.tap(shareBtnFinder);
      await tester.pumpAndSettle();

      expect(fakeShare.shareCount, 1);
    });

    testWidgets('Exibe estado de erro e botão Tentar Novamente com min 48dp', (tester) async {
      final fakeGenerator = FakePdfReportGenerator(
        result: const Failure(
          ValidationError(
            code: ReportFailureCodes.pdfGenerationFailed,
            message: 'Erro simulado na compilação do laudo.',
          ),
        ),
      );
      final fakeShare = FakeShareService();

      final controller = ReportPreviewController(
        reportData: sampleData,
        pdfGenerator: fakeGenerator,
        shareService: fakeShare,
        tempPathResolver: () async => '/tmp/laudo_err.pdf',
        fileSaver: (_, _) async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KortexScope(
            providers: [
              KortexProvider<ReportPreviewController>(
                create: (_) => controller,
                dispose: (c) => c.dispose(),
              ),
            ],
            child: const ReportPreviewPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Erro simulado na compilação do laudo.'), findsOneWidget);

      final retryBtnFinder = find.widgetWithText(FilledButton, 'Tentar Novamente');
      expect(retryBtnFinder, findsOneWidget);

      final retrySize = tester.getSize(retryBtnFinder);
      expect(retrySize.height, greaterThanOrEqualTo(48.0));
      expect(retrySize.width, greaterThanOrEqualTo(48.0));
    });

    testWidgets('ReportsRoutes monta escopo appScopedRoute e navega para preview', (tester) async {
      final fakeGenerator = FakePdfReportGenerator();
      final fakeShare = FakeShareService();

      final routes = ReportsRoutes(
        pdfGenerator: fakeGenerator,
        shareService: fakeShare,
        tempPathResolver: () async => '/tmp/laudo_route.pdf',
        fileSaver: (_, _) async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('btn-open-preview'),
                  onPressed: () {
                    Navigator.of(context).push(routes.preview(sampleData));
                  },
                  child: const Text('Abrir Preview'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('btn-open-preview')));
      await tester.pump(); // Inicia transição e montagem da rota escopada
      await tester.pump(const Duration(milliseconds: 300)); // Animação de rota
      await tester.pumpAndSettle(); // Aguarda estabilizar

      expect(find.text('Laudo Técnico'), findsOneWidget);
      expect(find.text('OS #OS-1001'), findsOneWidget);
    });
  });
}
