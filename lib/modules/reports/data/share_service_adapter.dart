// Adaptador do serviço nativo de compartilhamento de laudo técnico (UC-05.03).
//
// SRP: Acoplar ao plugin share_plus para invocar a folha nativa de compartilhamento
// sem vazar detalhes para o domínio ou UI.

import 'dart:io';

import 'package:kortex_lib/kortex_lib.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/ports/report_failure_codes.dart';
import '../domain/ports/share_service_port.dart';

/// Assinatura da função invocadora de compartilhamento nativo (injetável para testes).
typedef NativeShareInvoker = Future<void> Function(
  List<XFile> files, {
  String? text,
  String? subject,
});

/// Implementação de [IShareServicePort] utilizando `share_plus`.
final class ShareServiceAdapter implements IShareServicePort {
  const ShareServiceAdapter({NativeShareInvoker? shareInvoker})
      : _shareInvoker = shareInvoker ?? _defaultShareInvoker;

  final NativeShareInvoker _shareInvoker;

  static Future<void> _defaultShareInvoker(
    List<XFile> files, {
    String? text,
    String? subject,
  }) async {
    await Share.shareXFiles(files, text: text, subject: subject);
  }

  @override
  Future<IResult<void, ValidationError>> sharePdfFile({
    required String filePath,
    required String title,
    String? subject,
  }) async {
    final trimmedPath = filePath.trim();
    if (trimmedPath.isEmpty) {
      return const Failure(
        ValidationError(
          code: ReportFailureCodes.invalidReportFileName,
          message: 'O caminho do arquivo do laudo não pode ser vazio.',
        ),
      );
    }

    final file = File(trimmedPath);
    if (!file.existsSync()) {
      return const Failure(
        ValidationError(
          code: ReportFailureCodes.invalidReportFileName,
          message: 'O arquivo do laudo não foi encontrado no armazenamento local.',
        ),
      );
    }

    try {
      final xFile = XFile(trimmedPath, mimeType: 'application/pdf');
      await _shareInvoker([xFile], text: title, subject: subject);
      return const Success(null);
    } catch (e) {
      return Failure(
        ValidationError(
          code: ReportFailureCodes.shareFailed,
          message: 'Falha ao acionar compartilhamento nativo: $e',
        ),
      );
    }
  }
}
