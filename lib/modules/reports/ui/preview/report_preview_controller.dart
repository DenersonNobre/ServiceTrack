// Controller de estado reativo para visualização e preview do laudo PDF (UC-05.02 / UC-05.03).
//
// SRP: Gerenciar compilação, ciclo de vida do arquivo temporário e disparo do compartilhamento
// com reatividade exclusiva kortex (KortexSignal). Não acopla à apresentação visual.

import 'dart:io';
import 'dart:typed_data';

import 'package:kortex_lib/kortex_lib.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/report_data.dart';
import '../../domain/ports/pdf_report_generator_port.dart';
import '../../domain/ports/report_storage_port.dart';
import '../../domain/ports/share_service_port.dart';

/// Assinatura da função resolutora de caminho de arquivo temporário (injetável para testes).
typedef TempPathResolver = Future<String> Function();

/// Assinatura da função de escrita de bytes em arquivo (injetável para testes).
typedef FileSaver = Future<void> Function(String path, Uint8List bytes);

/// Controller Kortex para visualização e compartilhamento do Laudo Técnico.
final class ReportPreviewController extends IKortexController {
  ReportPreviewController({
    required this.reportData,
    required this.pdfGenerator,
    required this.shareService,
    this.reportStorage,
    TempPathResolver? tempPathResolver,
    FileSaver? fileSaver,
  })  : _tempPathResolver = tempPathResolver ?? _defaultTempPathResolver(reportData.workOrderId),
        _fileSaver = fileSaver ?? _defaultFileSaver;

  final ReportData reportData;
  final IPdfReportGeneratorPort pdfGenerator;
  final IShareServicePort shareService;
  final IReportStoragePort? reportStorage;
  final TempPathResolver _tempPathResolver;
  final FileSaver _fileSaver;

  /// Sinais reativos Kortex
  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<Uint8List?> generatedBytes = KortexSignal<Uint8List?>(null);
  final KortexSignal<String?> filePath = KortexSignal<String?>(null);
  final KortexSignal<String?> errorMessage = KortexSignal<String?>(null);
  final KortexSignal<bool> sharing = KortexSignal<bool>(false);

  bool _initialized = false;

  /// Garante compilação na inicialização da página
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await generate();
  }

  /// Gera ou recupera o laudo PDF e salva o arquivo em disco local temporário para visualização/compartilhamento.
  Future<void> generate() async {
    loading.value = true;
    errorMessage.value = null;

    final storage = reportStorage;
    if (storage != null) {
      final exists = await storage.hasSavedReport(reportData.workOrderId);
      if (exists) {
        final savedResult = await storage.getSavedReport(reportData.workOrderId);
        switch (savedResult) {
          case Success<Uint8List, ValidationError>(:final value):
            generatedBytes.value = value;
            try {
              final path = await _tempPathResolver();
              await _fileSaver(path, value);
              filePath.value = path;
              loading.value = false;
              return;
            } catch (e) {
              loading.value = false;
              errorMessage.value = 'Falha ao salvar arquivo temporário do laudo: $e';
              return;
            }
          case Failure<Uint8List, ValidationError>():
            // Se falhou ao ler do storage, continua para gerar normalmente com o generator
            break;
        }
      }
    }

    final result = await pdfGenerator.generatePdf(reportData);

    switch (result) {
      case Success<Uint8List, ValidationError>(:final value):
        generatedBytes.value = value;
        if (storage != null) {
          await storage.saveReport(
            workOrderId: reportData.workOrderId,
            bytes: value,
          );
        }
        try {
          final path = await _tempPathResolver();
          await _fileSaver(path, value);
          filePath.value = path;
          loading.value = false;
        } catch (e) {
          loading.value = false;
          errorMessage.value = 'Falha ao salvar arquivo temporário do laudo: $e';
        }
      case Failure<Uint8List, ValidationError>(:final value):
        loading.value = false;
        generatedBytes.value = null;
        filePath.value = null;
        errorMessage.value = value.message;
    }
  }

  /// Dispara compartilhamento com 1 toque nativo via [IShareServicePort] (UC-05.03).
  Future<bool> share() async {
    final currentPath = filePath.value;
    if (currentPath == null || currentPath.isEmpty) {
      errorMessage.value = 'O arquivo do laudo ainda não está disponível para envio.';
      return false;
    }

    sharing.value = true;
    try {
      final title = 'Laudo Técnico - OS #${reportData.workOrderId}';
      final result = await shareService.sharePdfFile(
        filePath: currentPath,
        title: title,
        subject: title,
      );
      sharing.value = false;
      return result.isSuccess;
    } catch (e) {
      sharing.value = false;
      errorMessage.value = 'Falha ao acionar folha de compartilhamento: $e';
      return false;
    }
  }

  static TempPathResolver _defaultTempPathResolver(String workOrderId) {
    return () async {
      final tempDir = await getTemporaryDirectory();
      final sanitizedId = workOrderId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      return '${tempDir.path}/laudo_$sanitizedId.pdf';
    };
  }

  static Future<void> _defaultFileSaver(String path, Uint8List bytes) async {
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  void onDispose() {
    loading.dispose();
    generatedBytes.dispose();
    filePath.dispose();
    errorMessage.dispose();
    sharing.dispose();
  }
}
