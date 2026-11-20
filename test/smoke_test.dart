import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/main.dart';

void main() {
  testWidgets('Smoke test inicial da aplicacao ServiceTrack', (WidgetTester tester) async {
    await tester.pumpWidget(const ServiceTrackApp());
    expect(find.text('ServiceTrack - Inicializado'), findsOneWidget);
  });
}
