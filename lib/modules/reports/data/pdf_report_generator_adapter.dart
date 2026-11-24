// Adaptador do motor de renderização de PDF on-device (UC-05.01 / INV-05).
//
// SRP: compilar o Laudo Técnico em PDF no padrão executivo Styleguide v2.1
// (Deep Petrol Green #115E59) usando package:pdf dentro de Isolate.run(...).

import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:kortex_lib/kortex_lib.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/models/report_data.dart';
import '../domain/ports/pdf_report_generator_port.dart';
import '../domain/ports/report_failure_codes.dart';

/// Implementação de [IPdfReportGeneratorPort] usando `package:pdf` em `Isolate.run(...)`.
final class PdfReportGeneratorAdapter implements IPdfReportGeneratorPort {
  const PdfReportGeneratorAdapter({
    this.regularFontBytes,
    this.boldFontBytes,
  });

  /// Bytes opcionais da fonte TTF regular (ex: PlusJakartaSans-Regular).
  final Uint8List? regularFontBytes;

  /// Bytes opcionais da fonte TTF bold (ex: PlusJakartaSans-Bold).
  final Uint8List? boldFontBytes;

  /// Carrega as fontes do bundle do app e inicializa o adaptador.
  static Future<PdfReportGeneratorAdapter> fromAssetBundle([
    AssetBundle? bundle,
  ]) async {
    final b = bundle ?? rootBundle;
    try {
      final reg = await b.load('assets/fonts/PlusJakartaSans-Regular.ttf');
      final bold = await b.load('assets/fonts/PlusJakartaSans-Bold.ttf');
      return PdfReportGeneratorAdapter(
        regularFontBytes: reg.buffer.asUint8List(),
        boldFontBytes: bold.buffer.asUint8List(),
      );
    } catch (_) {
      // Fallback gracioso para fontes nativas do PDF caso bundle não carregue
      return const PdfReportGeneratorAdapter();
    }
  }

  @override
  Future<IResult<Uint8List, ValidationError>> generatePdf(ReportData data) async {
    if (data.status != 'COMPLETED') {
      return const Failure(
        ValidationError(
          code: ReportFailureCodes.workOrderNotCompleted,
          message: 'O laudo técnico só pode ser gerado para Ordens de Serviço concluídas.',
        ),
      );
    }

    try {
      final bytes = await Isolate.run(
        () => _compilePdf(
          data: data,
          regularFontBytes: regularFontBytes,
          boldFontBytes: boldFontBytes,
        ),
      );
      return Success(bytes);
    } catch (e) {
      return Failure(
        ValidationError(
          code: ReportFailureCodes.pdfGenerationFailed,
          message: 'Erro ao compilar laudo PDF: $e',
        ),
      );
    }
  }

  static Future<Uint8List> _compilePdf({
    required ReportData data,
    Uint8List? regularFontBytes,
    Uint8List? boldFontBytes,
  }) async {
    final pdf = pw.Document();

    final pw.Font baseFont = regularFontBytes != null
        ? pw.Font.ttf(regularFontBytes.buffer.asByteData())
        : pw.Font.helvetica();
    final pw.Font boldFont = boldFontBytes != null
        ? pw.Font.ttf(boldFontBytes.buffer.asByteData())
        : pw.Font.helveticaBold();

    final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);

    final brandColor = PdfColor.fromHex('115E59'); // Deep Petrol Green
    final lightSurface = PdfColor.fromHex('FBF9F5'); // Warm Surface
    final gray700 = PdfColor.fromHex('374151');
    final gray500 = PdfColor.fromHex('6B7280');
    final borderGray = PdfColor.fromHex('E5E7EB');

    pw.MemoryImage? logoImage;
    if (data.technicianLogoBytes != null && data.technicianLogoBytes!.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(data.technicianLogoBytes!);
      } catch (_) {}
    }

    pw.MemoryImage? signatureImage;
    if (data.signaturePngBytes != null && data.signaturePngBytes!.isNotEmpty) {
      try {
        signatureImage = pw.MemoryImage(data.signaturePngBytes!);
      } catch (_) {}
    }

    final photoImages = <pw.MemoryImage>[];
    for (final p in data.photos) {
      try {
        photoImages.add(pw.MemoryImage(p.bytes));
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          margin: const pw.EdgeInsets.all(32),
          buildBackground: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: PdfColors.white),
          ),
        ),
        header: (context) => _buildHeader(
          data: data,
          brandColor: brandColor,
          gray700: gray700,
          gray500: gray500,
          logoImage: logoImage,
        ),
        footer: (context) => _buildFooter(
          context: context,
          brandColor: brandColor,
          gray500: gray500,
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildInfoCards(
            data: data,
            brandColor: brandColor,
            lightSurface: lightSurface,
            borderGray: borderGray,
            gray700: gray700,
          ),
          pw.SizedBox(height: 16),
          _buildServiceSection(
            data: data,
            brandColor: brandColor,
            lightSurface: lightSurface,
            borderGray: borderGray,
            gray700: gray700,
          ),
          if (data.checklistItems.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildChecklistSection(
              data: data,
              brandColor: brandColor,
              borderGray: borderGray,
              gray700: gray700,
            ),
          ],
          if (photoImages.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildPhotosSection(
              photoImages: photoImages,
              brandColor: brandColor,
              borderGray: borderGray,
            ),
          ],
          pw.SizedBox(height: 20),
          _buildSignatureSection(
            data: data,
            signatureImage: signatureImage,
            brandColor: brandColor,
            borderGray: borderGray,
            gray700: gray700,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required ReportData data,
    required PdfColor brandColor,
    required PdfColor gray700,
    required PdfColor gray500,
    pw.MemoryImage? logoImage,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: brandColor, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  data.technicianCommercialName ?? data.technicianName ?? 'ServiceTrack',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: brandColor,
                  ),
                ),
                if (data.technicianPhone != null && data.technicianPhone!.isNotEmpty)
                  pw.Text(
                    'Contato: ${data.technicianPhone}',
                    style: pw.TextStyle(fontSize: 9, color: gray700),
                  ),
                pw.Text(
                  'Laudo Técnico de Atendimento - OS #${data.workOrderId}',
                  style: pw.TextStyle(fontSize: 8, color: gray500),
                ),
              ],
            ),
          ),
          if (logoImage != null)
            pw.Container(
              width: 50,
              height: 50,
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter({
    required pw.Context context,
    required PdfColor brandColor,
    required PdfColor gray500,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Documento gerado eletronicamente via ServiceTrack Standalone (Offline-First)',
            style: pw.TextStyle(fontSize: 7, color: gray500),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 7, color: gray500, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoCards({
    required ReportData data,
    required PdfColor brandColor,
    required PdfColor lightSurface,
    required PdfColor borderGray,
    required PdfColor gray700,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightSurface,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: borderGray, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DADOS DO CLIENTE',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brandColor),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  data.customerName ?? 'Cliente não informado',
                  style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                if (data.customerDocument != null && data.customerDocument!.isNotEmpty)
                  pw.Text('Doc: ${data.customerDocument}', style: pw.TextStyle(fontSize: 8, color: gray700)),
                if (data.customerPhone != null && data.customerPhone!.isNotEmpty)
                  pw.Text('WhatsApp: ${data.customerPhone}', style: pw.TextStyle(fontSize: 8, color: gray700)),
                if (data.locationAddress != null && data.locationAddress!.isNotEmpty)
                  pw.Text('Endereço: ${data.locationAddress}', style: pw.TextStyle(fontSize: 8, color: gray700)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightSurface,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: borderGray, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DETALHES DO ATENDIMENTO',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brandColor),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Data Agendada: ${data.scheduledDateFormatted}', style: pw.TextStyle(fontSize: 8, color: gray700)),
                if (data.completedDateFormatted != null)
                  pw.Text('Conclusão: ${data.completedDateFormatted}', style: pw.TextStyle(fontSize: 8, color: gray700)),
                if (data.estimatedAmountFormatted != null)
                  pw.Text('Valor do Serviço: ${data.estimatedAmountFormatted}', style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                if (data.checkInGpsFormatted != null)
                  pw.Text('Check-in GPS: ${data.checkInGpsFormatted}', style: pw.TextStyle(fontSize: 7, color: gray700)),
                if (data.checkOutGpsFormatted != null)
                  pw.Text('Check-out GPS: ${data.checkOutGpsFormatted}', style: pw.TextStyle(fontSize: 7, color: gray700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildServiceSection({
    required ReportData data,
    required PdfColor brandColor,
    required PdfColor lightSurface,
    required PdfColor borderGray,
    required PdfColor gray700,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderGray, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DESCRIÇÃO DOS SERVIÇOS EXECUTADOS',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brandColor),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data.serviceDescription,
            style: pw.TextStyle(fontSize: 9, color: gray700, lineSpacing: 1.3),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildChecklistSection({
    required ReportData data,
    required PdfColor brandColor,
    required PdfColor borderGray,
    required PdfColor gray700,
  }) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CHECKLIST TÉCNICO DE CONFORMIDADE',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandColor),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderGray, width: 0.5),
            headerStyle: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: brandColor),
            cellStyle: pw.TextStyle(fontSize: 8, color: gray700),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            headers: const ['Item de Verificação', 'Situação', 'Observações'],
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(2.5),
            },
            data: data.checklistItems.map((item) {
              return [
                item.title,
                item.statusDescription,
                item.notes ?? '-',
              ];
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPhotosSection({
    required List<pw.MemoryImage> photoImages,
    required PdfColor brandColor,
    required PdfColor borderGray,
  }) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EVIDÊNCIAS FOTOGRÁFICAS (${photoImages.length})',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandColor),
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: photoImages.map((img) {
              return pw.Container(
                width: 140,
                height: 105,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderGray, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 4,
                  verticalRadius: 4,
                  child: pw.Image(img, fit: pw.BoxFit.cover),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureSection({
    required ReportData data,
    required PdfColor brandColor,
    required PdfColor borderGray,
    required PdfColor gray700,
    pw.MemoryImage? signatureImage,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderGray, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            children: [
              pw.Container(
                width: 180,
                height: 40,
                child: pw.Center(
                  child: pw.Text(
                    data.technicianName ?? 'Técnico Responsável',
                    style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.Container(width: 180, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text('Assinatura do Técnico', style: pw.TextStyle(fontSize: 7, color: gray700)),
            ],
          ),
          pw.Column(
            children: [
              pw.Container(
                width: 180,
                height: 40,
                child: signatureImage != null
                    ? pw.Image(signatureImage, fit: pw.BoxFit.contain)
                    : pw.Center(
                        child: pw.Text('Assinatura Digital Registrada', style: const pw.TextStyle(fontSize: 7)),
                      ),
              ),
              pw.Container(width: 180, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text(
                data.signerName != null ? 'Recebedor: ${data.signerName}' : 'Assinatura do Recebedor',
                style: pw.TextStyle(fontSize: 7, color: gray700),
              ),
              if (data.signerDocument != null)
                pw.Text('Doc: ${data.signerDocument}', style: pw.TextStyle(fontSize: 6, color: gray700)),
            ],
          ),
        ],
      ),
    );
  }
}
