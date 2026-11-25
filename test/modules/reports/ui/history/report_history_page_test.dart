import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';
import 'package:service_track/modules/reports/domain/models/report_data.dart';
import 'package:service_track/modules/reports/domain/models/report_history_item.dart';
import 'package:service_track/modules/reports/domain/ports/pdf_report_generator_port.dart';
import 'package:service_track/modules/reports/domain/ports/share_service_port.dart';
import 'package:service_track/modules/reports/ui/history/report_history_controller.dart';
import 'package:service_track/modules/reports/ui/history/report_history_page.dart';
import 'package:service_track/modules/reports/ui/reports_routes.dart';

final class _FakePdfGenerator implements IPdfReportGeneratorPort {
  @override
  Future<IResult<Uint8List, ValidationError>> generatePdf(
    ReportData data,
  ) async {
    throw UnimplementedError();
  }
}

final class _FakeShareService implements IShareServicePort {
  @override
  Future<IResult<void, ValidationError>> sharePdfFile({
    required String filePath,
    required String title,
    String? subject,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  const items = [
    ReportHistoryItem(
      workOrderId: 'OS-10',
      serviceDescription: 'Reparo elétrico',
      scheduledDateFormatted: '25/11/2026 14:00',
      completedDateFormatted: '25/11/2026 15:30',
      customerName: 'Cliente Alfa',
      status: 'COMPLETED',
    ),
  ];

  Widget buildPage({
    required ReportHistoryController controller,
    required void Function(String workOrderId) onOpenReport,
  }) {
    return MaterialApp(
      home: KortexScope(
        providers: [
          KortexProvider<ReportHistoryController>(
            create: (_) => controller,
            dispose: (c) => c.dispose(),
          ),
        ],
        child: ReportHistoryPage(onOpenReport: onOpenReport),
      ),
    );
  }

  group('ReportHistoryPage', () {
    testWidgets('exibe estado vazio quando não há laudos', (tester) async {
      final controller = ReportHistoryController(
        loadHistory: () async =>
            const Success<List<ReportHistoryItem>, ValidationError>([]),
      );

      await tester.pumpWidget(
        buildPage(controller: controller, onOpenReport: (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhum laudo disponível.'), findsOneWidget);

    });

    testWidgets('renderiza item e aciona abertura do laudo', (tester) async {
      final opened = <String>[];
      final controller = ReportHistoryController(
        loadHistory: () async =>
            const Success<List<ReportHistoryItem>, ValidationError>(items),
      );

      await tester.pumpWidget(
        buildPage(controller: controller, onOpenReport: opened.add),
      );
      await tester.pumpAndSettle();

      expect(find.text('OS #OS-10'), findsOneWidget);
      expect(find.textContaining('Reparo elétrico'), findsWidgets);
      expect(find.textContaining('Cliente Alfa'), findsWidgets);

      final action = find.byKey(const Key('report-history-open-OS-10'));
      expect(action, findsOneWidget);
      final size = tester.getSize(action);
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));

      await tester.tap(action);
      await tester.pump();

      expect(opened, ['OS-10']);
    });

    testWidgets('exibe erro e permite tentar novamente', (tester) async {
      var calls = 0;
      final controller = ReportHistoryController(
        loadHistory: () async {
          calls++;
          if (calls == 1) {
            return const Failure(
              ValidationError(
                code: 'ERR',
                message: 'Falha ao carregar histórico.',
              ),
            );
          }
          return const Success<List<ReportHistoryItem>, ValidationError>(items);
        },
      );

      await tester.pumpWidget(
        buildPage(controller: controller, onOpenReport: (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('Falha ao carregar histórico.'), findsOneWidget);
      final retry = find.byKey(const Key('report-history-retry'));
      expect(retry, findsOneWidget);
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));

      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('OS #OS-10'), findsOneWidget);
    });
  });

  group('ReportsRoutes.history', () {
    testWidgets('monta rota escopada de histórico', (tester) async {
      final routes = ReportsRoutes(
        pdfGenerator: _FakePdfGenerator(),
        shareService: _FakeShareService(),
      );
      final opened = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  routes.history(
                    loadHistory: () async => const Success<
                        List<ReportHistoryItem>, ValidationError>(items),
                    onOpenReport: opened.add,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Histórico de Laudos'), findsOneWidget);
      expect(find.text('OS #OS-10'), findsOneWidget);
      await tester.tap(find.byKey(const Key('report-history-open-OS-10')));
      await tester.pump();
      expect(opened, ['OS-10']);
    });
  });
}
