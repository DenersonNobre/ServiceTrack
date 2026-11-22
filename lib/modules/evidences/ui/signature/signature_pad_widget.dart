// Widget de coleta de assinatura digital em canvas (UC-04.04 / DESIGN.md §4.3).
//
// SRP: renderizar canvas de assinatura + nome + documento e emitir DigitalSignature.

import 'dart:typed_data';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/.index.dart';
import '../../domain/entities/digital_signature.dart';

/// Canvas tátil para coleta de assinatura digital do cliente.
final class SignaturePadWidget extends StatefulWidget {
  /// Cria o widget de coleta de assinatura.
  const SignaturePadWidget({
    super.key,
    required this.onConfirmed,
    this.requireDocumentByPolicy = false,
  });

  /// Callback acionado com [DigitalSignature] validada.
  final void Function(DigitalSignature signature) onConfirmed;

  /// Política C-03: documento obrigatório apenas quando habilitado (default minimização).
  final bool requireDocumentByPolicy;

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  late final SignatureController _sigController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _docController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sigController = SignatureController(
      penStrokeWidth: 3,
      penColor: AppColors.gray900,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _sigController.dispose();
    _nameController.dispose();
    _docController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final bytes = _sigController.isEmpty
        ? Uint8List(0)
        : (await _sigController.toPngBytes()) ?? Uint8List(0);
    final result = DigitalSignature.tryCreate(
      signatureBytes: bytes,
      signerName: _nameController.text,
      documentNumber: _docController.text,
      requireDocumentByPolicy: widget.requireDocumentByPolicy,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success<DigitalSignature, ValidationError>(:final value):
        widget.onConfirmed(value);
      case Failure<DigitalSignature, ValidationError>(:final value):
        setState(() => _error = value.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Signature(
              key: const Key('signature-canvas'),
              controller: _sigController,
              backgroundColor: AppColors.surfaceCard,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('signature-signer-name'),
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nome completo do recebedor',
            filled: true,
            fillColor: AppColors.surfaceCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (widget.requireDocumentByPolicy) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('signature-signer-doc'),
            controller: _docController,
            decoration: InputDecoration(
              labelText: 'Documento (CPF/RG)',
              filled: true,
              fillColor: AppColors.surfaceCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: OutlinedButton(
                  key: const Key('signature-clear'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saving ? null : _sigController.clear,
                  child: const Text('Limpar'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppPrimaryButton(
                key: const Key('signature-confirm'),
                label: 'Confirmar',
                loading: _saving,
                onPressed: _confirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
