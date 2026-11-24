// Bindings de rotas escopadas do módulo de Relatórios e Laudos PDF (UC-05.02 / UC-05.03).
//
// SRP: Definir rotas com injeção escopada Kortex para laudos técnicos.

import 'package:flutter/material.dart';

import '../../../core/ui/app_scoped_route.dart';
import '../domain/models/report_data.dart';
import '../domain/ports/pdf_report_generator_port.dart';
import '../domain/ports/report_storage_port.dart';
import '../domain/ports/share_service_port.dart';
import 'preview/report_preview_controller.dart';
import 'preview/report_preview_page.dart';

/// Bindings de rotas do módulo de relatórios.
final class ReportsRoutes {
  const ReportsRoutes({
    required this.pdfGenerator,
    required this.shareService,
    this.reportStorage,
    this.tempPathResolver,
    this.fileSaver,
  });

  final IPdfReportGeneratorPort pdfGenerator;
  final IShareServicePort shareService;
  final IReportStoragePort? reportStorage;
  final TempPathResolver? tempPathResolver;
  final FileSaver? fileSaver;

  /// Rota escopada para pré-visualização e envio do laudo PDF.
  Route<void> preview(ReportData data) {
    return appScopedRoute<ReportPreviewController, void>(
      create: (_) => ReportPreviewController(
        reportData: data,
        pdfGenerator: pdfGenerator,
        shareService: shareService,
        reportStorage: reportStorage,
        tempPathResolver: tempPathResolver,
        fileSaver: fileSaver,
      ),
      builder: (context, _) => const ReportPreviewPage(),
    );
  }
}
