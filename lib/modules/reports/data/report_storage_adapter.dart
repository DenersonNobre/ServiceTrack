// Implementação do adaptador de armazenamento local de laudos em PDF (UC-05.04).
//
// SRP: Gerenciar leitura, escrita e existência de laudos no sistema de arquivos local.
// Isolado de regras de negócio de visualização e compilação.

import 'dart:io';
import 'dart:typed_data';

import 'package:kortex_lib/kortex_lib.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/ports/report_failure_codes.dart';
import '../domain/ports/report_storage_port.dart';

/// Adaptador para armazenamento de laudos técnicos em diretório local da aplicação.
final class ReportStorageAdapter implements IReportStoragePort {
  ReportStorageAdapter({this.baseDirectoryPath});

  final String? baseDirectoryPath;

  Future<String> _resolveReportsDirectory() async {
    final basePath = baseDirectoryPath ?? (await getApplicationSupportDirectory()).path;
    final reportsDir = Directory('$basePath/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    return reportsDir.path;
  }

  String _sanitizeId(String workOrderId) {
    return workOrderId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  @override
  Future<bool> hasSavedReport(String workOrderId) async {
    final trimmedId = workOrderId.trim();
    if (trimmedId.isEmpty) return false;

    try {
      final dirPath = await _resolveReportsDirectory();
      final sanitized = _sanitizeId(trimmedId);
      final file = File('$dirPath/OS-$sanitized.pdf');
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<IResult<Uint8List, ValidationError>> getSavedReport(String workOrderId) async {
    final trimmedId = workOrderId.trim();
    if (trimmedId.isEmpty) {
      return const Failure(
        ValidationError(
          code: ReportFailureCodes.invalidReportFileName,
          message: 'Identificador da Ordem de Serviço inválido para recuperação de laudo.',
        ),
      );
    }

    try {
      final dirPath = await _resolveReportsDirectory();
      final sanitized = _sanitizeId(trimmedId);
      final file = File('$dirPath/OS-$sanitized.pdf');

      if (!await file.exists()) {
        return const Failure(
          ValidationError(
            code: ReportFailureCodes.reportNotFound,
            message: 'Nenhum laudo salvo encontrado para esta Ordem de Serviço.',
          ),
        );
      }

      final bytes = await file.readAsBytes();
      return Success(bytes);
    } catch (e) {
      return Failure(
        ValidationError(
          code: ReportFailureCodes.storageFailed,
          message: 'Falha ao ler laudo salvo do disco: $e',
        ),
      );
    }
  }

  @override
  Future<IResult<String, ValidationError>> saveReport({
    required String workOrderId,
    required Uint8List bytes,
  }) async {
    final trimmedId = workOrderId.trim();
    if (trimmedId.isEmpty) {
      return const Failure(
        ValidationError(
          code: ReportFailureCodes.invalidReportFileName,
          message: 'Identificador da Ordem de Serviço inválido para gravação de laudo.',
        ),
      );
    }

    try {
      final dirPath = await _resolveReportsDirectory();
      final sanitized = _sanitizeId(trimmedId);
      final filePath = '$dirPath/OS-$sanitized.pdf';
      final file = File(filePath);

      await file.writeAsBytes(bytes, flush: true);
      return Success(filePath);
    } catch (e) {
      return Failure(
        ValidationError(
          code: ReportFailureCodes.storageFailed,
          message: 'Falha ao gravar arquivo de laudo em disco: $e',
        ),
      );
    }
  }
}
