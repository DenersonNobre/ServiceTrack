import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:kortex_lib/core/models/money.dart';

import '../../checklists/domain/entities/checklist_answer.dart';
import '../../checklists/domain/entities/checklist_template.dart';
import '../../customers/domain/value_objects/customer.dart';
import '../../profile/domain/value_objects/technician_profile.dart';
import '../../work_orders/domain/value_objects/check_in_record.dart';
import '../../work_orders/domain/value_objects/geo_point.dart';
import '../../work_orders/domain/value_objects/work_order.dart';
import '../domain/models/report_data.dart';

/// Monta [ReportData] a partir das entidades reais do atendimento.
///
/// SRP: transformar agregados/entidades em DTO desacoplado para o laudo PDF.
/// Não acessa I/O, não persiste, não depende de UI.
final class ReportDataAssembler {
  const ReportDataAssembler._();

  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  static ReportData assemble({
    required WorkOrder workOrder,
    required Customer? customer,
    required TechnicianProfile? technicianProfile,
    required ChecklistTemplate? template,
    required List<ChecklistAnswer> answers,
    Uint8List? technicianLogoBytes,
  }) {
    final checkOut = workOrder.checkOut;
    final signature = workOrder.signature;
    final commercialName = technicianProfile?.commercialName.value;

    return ReportData(
      workOrderId: workOrder.id,
      status: workOrder.status.code,
      serviceDescription: workOrder.serviceDescription,
      scheduledDateFormatted: _formatDateTime(workOrder.scheduledAt),
      completedDateFormatted:
          checkOut == null ? null : _formatDateTime(checkOut.timestampUtc),
      technicianName: commercialName,
      technicianCommercialName: commercialName,
      technicianPhone: technicianProfile?.whatsapp.digits,
      technicianLogoBytes: technicianLogoBytes,
      customerName: customer?.name.value,
      customerDocument: customer?.document?.digits,
      customerPhone: customer?.whatsapp.digits,
      locationAddress: null,
      estimatedAmountFormatted: _formatMoney(workOrder.estimatedValue),
      checklistItems: _mapChecklistItems(template: template, answers: answers),
      photos: const [],
      signaturePngBytes: signature?.signatureBytes,
      signerName: signature?.signerName,
      signerDocument: signature?.documentNumber,
      checkInGpsFormatted: _formatCheckIn(workOrder.checkIn),
      checkOutGpsFormatted: _formatGeoPoint(checkOut),
    );
  }

  static List<ReportChecklistItem> _mapChecklistItems({
    required ChecklistTemplate? template,
    required List<ChecklistAnswer> answers,
  }) {
    if (template == null) return const [];

    final answersByItemId = <String, ChecklistAnswer>{
      for (final answer in answers) answer.itemId: answer,
    };

    return template.items
        .map((item) {
          final answer = answersByItemId[item.id];
          return ReportChecklistItem(
            title: item.title,
            statusDescription: _statusDescription(answer?.status),
            notes: _normalizeNotes(answer?.notes),
          );
        })
        .toList(growable: false);
  }

  static String _statusDescription(ChecklistAnswerStatus? status) {
    return switch (status) {
      ChecklistAnswerStatus.conforme => 'Conforme',
      ChecklistAnswerStatus.naoConforme => 'Não conforme',
      ChecklistAnswerStatus.naoAplica => 'Não se aplica',
      null => 'Sem resposta',
    };
  }

  static String? _normalizeNotes(String? notes) {
    final trimmed = notes?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String _formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  static String _formatMoney(Money money) {
    final amount = money.minorUnits.toDouble() / 100.0;
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(amount);
  }

  static String? _formatCheckIn(CheckInRecord? checkIn) {
    return switch (checkIn) {
      CheckInGps(:final point) => _formatGeoPoint(point),
      CheckInBypassed() => null,
      null => null,
    };
  }

  static String? _formatGeoPoint(GeoPoint? point) {
    if (point == null) return null;
    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }
}
