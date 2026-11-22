// Entidade de Evidência Fotográfica e cota INV-04 (UC-04.03).
//
// SRP: validar metadados, tamanho máximo (<= 400KB) e cota de 6 fotos por OS.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../ports/evidence_failure_codes.dart';

/// Limite máximo de fotos por Ordem de Serviço no MVP (INV-04).
const int kMaxPhotosPerWorkOrder = 6;

/// Limite máximo em bytes de cada foto comprimida (RNF-03 / UC-04.03).
const int kMaxPhotoSizeBytes = 400 * 1024;

/// Evidência fotográfica compactada com metadados de auditoria.
final class PhotoEvidence {
  const PhotoEvidence._({
    required this.id,
    required this.workOrderId,
    required this.filePath,
    required this.sizeBytes,
    required this.capturedAtUtc,
    this.latitude,
    this.longitude,
  });

  /// Identificador único da foto.
  final String id;

  /// Identificador da Ordem de Serviço.
  final String workOrderId;

  /// Caminho no diretório privado da aplicação.
  final String filePath;

  /// Tamanho em bytes da foto já compactada.
  final int sizeBytes;

  /// Carimbo UTC da captura.
  final DateTime capturedAtUtc;

  /// Latitude opcional no momento do clique.
  final double? latitude;

  /// Longitude opcional no momento do clique.
  final double? longitude;

  /// Cria evidência validando cota `INV-04`, tamanho e coordenadas.
  static IResult<PhotoEvidence, ValidationError> tryCreate({
    required String id,
    required String workOrderId,
    required String filePath,
    required int sizeBytes,
    required int existingCount,
    DateTime? capturedAtUtc,
    double? latitude,
    double? longitude,
  }) {
    if (existingCount >= kMaxPhotosPerWorkOrder) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.evidenceLimitExceeded,
          message: 'Limite máximo de 6 fotos por Ordem de Serviço atingido.',
        ),
      );
    }
    if (id.trim().isEmpty ||
        workOrderId.trim().isEmpty ||
        filePath.trim().isEmpty) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.invalidEvidenceData,
          message: 'Dados obrigatórios da evidência ausentes.',
        ),
      );
    }
    if (sizeBytes <= 0 || sizeBytes > kMaxPhotoSizeBytes) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.invalidEvidenceSize,
          message: 'A foto comprimida deve ter entre 1 byte e 400 KB.',
        ),
      );
    }
    if (latitude != null && (!latitude.isFinite || latitude < -90 || latitude > 90)) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.invalidGeo,
          message: 'Latitude fora do intervalo válido.',
        ),
      );
    }
    if (longitude != null && (!longitude.isFinite || longitude < -180 || longitude > 180)) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.invalidGeo,
          message: 'Longitude fora do intervalo válido.',
        ),
      );
    }
    return Success(
      PhotoEvidence._(
        id: id.trim(),
        workOrderId: workOrderId.trim(),
        filePath: filePath.trim(),
        sizeBytes: sizeBytes,
        capturedAtUtc: (capturedAtUtc ?? DateTime.now()).toUtc(),
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  @override
  String toString() => 'PhotoEvidence(id=$id, sizeBytes=$sizeBytes)';
}
