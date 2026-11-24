// Modelo de dados desacoplado para compilação do Laudo Técnico (UC-05.01).
//
// SRP: encapsular os dados necessários para renderizar o Laudo PDF executivo
// em Isolate.run(...) sem reter referências a closures ou dependências de UI.

import 'dart:typed_data';

/// Item de checklist compilado para exibição no laudo.
final class ReportChecklistItem {
  const ReportChecklistItem({
    required this.title,
    required this.statusDescription,
    this.notes,
  });

  final String title;
  final String statusDescription;
  final String? notes;
}

/// Evidência fotográfica para o grid do laudo.
final class ReportPhotoEvidence {
  const ReportPhotoEvidence({
    required this.bytes,
    this.caption,
    this.timestampFormatted,
  });

  final Uint8List bytes;
  final String? caption;
  final String? timestampFormatted;
}

/// Dados completos da Ordem de Serviço e atores para o PDF.
final class ReportData {
  const ReportData({
    required this.workOrderId,
    required this.status,
    required this.serviceDescription,
    required this.scheduledDateFormatted,
    this.completedDateFormatted,
    this.technicianName,
    this.technicianCommercialName,
    this.technicianPhone,
    this.technicianLogoBytes,
    this.customerName,
    this.customerDocument,
    this.customerPhone,
    this.locationAddress,
    this.estimatedAmountFormatted,
    this.checklistItems = const [],
    this.photos = const [],
    this.signaturePngBytes,
    this.signerName,
    this.signerDocument,
    this.checkInGpsFormatted,
    this.checkOutGpsFormatted,
  });

  final String workOrderId;
  final String status;
  final String serviceDescription;
  final String scheduledDateFormatted;
  final String? completedDateFormatted;
  final String? technicianName;
  final String? technicianCommercialName;
  final String? technicianPhone;
  final Uint8List? technicianLogoBytes;
  final String? customerName;
  final String? customerDocument;
  final String? customerPhone;
  final String? locationAddress;
  final String? estimatedAmountFormatted;
  final List<ReportChecklistItem> checklistItems;
  final List<ReportPhotoEvidence> photos;
  final Uint8List? signaturePngBytes;
  final String? signerName;
  final String? signerDocument;
  final String? checkInGpsFormatted;
  final String? checkOutGpsFormatted;
}
