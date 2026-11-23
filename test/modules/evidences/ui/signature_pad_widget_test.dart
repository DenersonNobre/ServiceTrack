// Testes do canvas de assinatura do recebedor (UC-04.04 / UC-06.03).
//
// SRP: provar que a captura inválida falha com a mensagem do VO canônico, que
// a captura válida emite DigitalSignature, que o campo de documento só aparece
// sob política C-03 e que os controles respeitam 48dp.
//
// O canvas é substituído por um SignatureController fake: a rasterização real
// (Picture.toImage) não completa sob o relógio sintético do widget test.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/evidences/domain/entities/digital_signature.dart';
import 'package:service_track/modules/evidences/ui/signature/signature_pad_controller.dart';
import 'package:service_track/modules/evidences/ui/signature/signature_pad_widget.dart';
import 'package:signature/signature.dart';

const List<int> _pngMagicBytes = <int>[137, 80, 78, 71, 13, 10, 26, 10];

final class _FakeSignatureController extends SignatureController {
  _FakeSignatureController({required this.hasStroke, Uint8List? png})
    : _png = png ?? Uint8List.fromList([..._pngMagicBytes, 0, 0, 0, 0]);

  final bool hasStroke;
  final Uint8List _png;

  @override
  bool get isEmpty => !hasStroke;

  @override
  Future<Uint8List?> toPngBytes({int? height, int? width}) async => _png;
}

Widget _host(SignaturePadWidget widget) =>
    MaterialApp(home: Scaffold(body: widget));

void main() {
  testWidgets('UC-04.04 - canvas vazio reprova sem emitir assinatura', (
    tester,
  ) async {
    final controller = SignaturePadController(
      signatureController: _FakeSignatureController(hasStroke: false),
    );
    DigitalSignature? confirmed;
    await tester.pumpWidget(
      _host(
        SignaturePadWidget(
          controller: controller,
          onConfirmed: (signature) => confirmed = signature,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('signature-signer-name')),
      'Maria Silva',
    );
    await tester.tap(find.byKey(const Key('signature-confirm')));
    await tester.pump();

    final expected = DigitalSignature.tryCreate(
      signatureBytes: Uint8List(0),
      signerName: 'Maria Silva',
    );
    expect(confirmed, isNull);
    expect(controller.error.value, expected.getOrNullFailure()!.message);
    expect(find.text(expected.getOrNullFailure()!.message), findsOneWidget);

    controller.dispose();
  });

  testWidgets('UC-04.04 - captura válida emite DigitalSignature', (
    tester,
  ) async {
    final controller = SignaturePadController(
      signatureController: _FakeSignatureController(hasStroke: true),
    );
    DigitalSignature? confirmed;
    await tester.pumpWidget(
      _host(
        SignaturePadWidget(
          controller: controller,
          onConfirmed: (signature) => confirmed = signature,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('signature-signer-name')),
      '  Maria   Silva ',
    );
    await tester.tap(find.byKey(const Key('signature-confirm')));
    await tester.pump();

    expect(confirmed, isNotNull);
    expect(confirmed!.signerName, 'Maria Silva');
    expect(confirmed!.documentNumber, isNull);
    expect(controller.error.value, isNull);

    controller.dispose();
  });

  testWidgets('UC-04.04 - campo de documento só existe sob política C-03', (
    tester,
  ) async {
    final controller = SignaturePadController(
      signatureController: _FakeSignatureController(hasStroke: false),
    );
    await tester.pumpWidget(
      _host(SignaturePadWidget(controller: controller, onConfirmed: (_) {})),
    );
    expect(find.byKey(const Key('signature-signer-doc')), findsNothing);

    await tester.pumpWidget(
      _host(
        SignaturePadWidget(
          controller: controller,
          requireDocumentByPolicy: true,
          onConfirmed: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('signature-signer-doc')), findsOneWidget);

    controller.dispose();
  });

  testWidgets('UC-06.02 - controles do canvas respeitam 48dp', (tester) async {
    final controller = SignaturePadController(
      signatureController: _FakeSignatureController(hasStroke: false),
    );
    await tester.pumpWidget(
      _host(SignaturePadWidget(controller: controller, onConfirmed: (_) {})),
    );

    expect(
      tester.getSize(find.byKey(const Key('signature-clear'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('signature-confirm'))).height,
      greaterThanOrEqualTo(48),
    );

    controller.dispose();
  });
}
