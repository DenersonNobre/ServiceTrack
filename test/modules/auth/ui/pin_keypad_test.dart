import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/auth/ui/lock/widgets/pin_keypad.dart';

void main() {
  testWidgets('PinKeypad exibe dígitos e botões >=48dp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinKeypad(
            onDigit: (_) {},
            onBackspace: () {},
            onSubmit: () {},
          ),
        ),
      ),
    );

    for (final d in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    final zeroButton = find.ancestor(
      of: find.text('0'),
      matching: find.byType(ElevatedButton),
    );
    final zeroSize = tester.getSize(zeroButton.first);
    expect(zeroSize.height, greaterThanOrEqualTo(48));
    expect(zeroSize.width, greaterThanOrEqualTo(48));
  });
}
