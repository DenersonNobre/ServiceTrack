// Controller Kortex do canvas de assinatura do recebedor (UC-04.04 / UC-06.03).
//
// SRP: manter o estado efêmero de captura (canvas + campos de texto), o flag de
// processamento e a mensagem de erro de validação; delegar a regra de negócio
// ao VO DigitalSignature. NÃO renderiza UI, NÃO persiste, NÃO acessa banco.
//
// Dependências: kortex (reatividade), signature (controlador do canvas),
// DigitalSignature (invariantes) e EvidenceFailureCodes (catálogo de falhas).

import 'dart:typed_data';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:signature/signature.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/digital_signature.dart';
import '../../domain/ports/evidence_failure_codes.dart';

/// Estado reativo da coleta de assinatura em canvas.
final class SignaturePadController extends IKortexController {
  /// Cria o controller; [signatureController] pode ser injetado em testes.
  SignaturePadController({SignatureController? signatureController})
    : signatureController =
          signatureController ??
          SignatureController(
            penStrokeWidth: 3,
            penColor: AppColors.gray900,
            exportBackgroundColor: Colors.white,
          );

  /// Controlador do canvas tátil (limpeza e exportação PNG).
  final SignatureController signatureController;

  /// Campo do nome completo do recebedor.
  final TextEditingController signerNameController = TextEditingController();

  /// Campo do documento do recebedor (CPF/RG), usado só sob política C-03.
  final TextEditingController signerDocumentController =
      TextEditingController();

  /// Indica processamento em andamento (desabilita ações concorrentes).
  final KortexSignal<bool> saving = KortexSignal<bool>(false);

  /// Mensagem de validação vigente, exibida sob o canvas.
  final KortexSignal<String?> error = KortexSignal<String?>(null);

  /// Limpa o canvas e a mensagem de erro vigente.
  void clear() {
    signatureController.clear();
    error.value = null;
  }

  /// Valida canvas/campos e devolve a assinatura canônica.
  ///
  /// Retorna [Failure] com código do catálogo quando a captura é inválida.
  Future<IResult<DigitalSignature, ValidationError>> confirm({
    required bool requireDocumentByPolicy,
  }) async {
    if (saving.value) {
      return const Failure(
        ValidationError(
          code: EvidenceFailureCodes.busy,
          message: 'Assinatura já está sendo processada.',
        ),
      );
    }
    saving.value = true;
    error.value = null;
    final bytes = signatureController.isEmpty
        ? Uint8List(0)
        : (await signatureController.toPngBytes()) ?? Uint8List(0);
    final document = signerDocumentController.text.trim();
    final result = DigitalSignature.tryCreate(
      signatureBytes: bytes,
      signerName: signerNameController.text,
      documentNumber: document.isEmpty ? null : document,
      requireDocumentByPolicy: requireDocumentByPolicy,
    );
    saving.value = false;
    if (result case Failure(:final value)) error.value = value.message;
    return result;
  }

  @override
  void onDispose() {
    signatureController.dispose();
    signerNameController.dispose();
    signerDocumentController.dispose();
    saving.dispose();
    error.dispose();
  }
}
