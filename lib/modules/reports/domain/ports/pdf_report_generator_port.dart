// Porta do motor de renderização de PDF on-device (UC-05.01).
//
// SRP: contrato para geração de arquivo binário PDF a partir de ReportData.

import 'dart:typed_data';

import 'package:kortex_lib/kortex_lib.dart';

import '../models/report_data.dart';

/// Contrato para o gerador de PDF executivo.
abstract interface class IPdfReportGeneratorPort {
  /// Gera o documento PDF binário (%PDF-) a partir de [data].
  ///
  /// Executa estritamente em `Isolate.run(...)` (`INV-05`) para garantir
  /// tempo de resposta célere sem engasgar a thread de UI.
  Future<IResult<Uint8List, ValidationError>> generatePdf(ReportData data);
}
