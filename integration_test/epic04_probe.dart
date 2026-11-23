// Sonda de ambiente para o E2E de device (EPIC-04).
//
// SRP: medir, no aparelho real, as duas premissas que o E2E vai depender —
// rota inicial do app (onboarding/lock/home) e capacidade real de captura de
// GPS (INV-SEC-19 faz a conclusão de OS falhar sem fix).
//
// Não afirma nada: imprime o resultado medido para decisão. Não é gate.

import 'package:dnolib/core/patterns/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:service_track/main.dart' as app;
import 'package:service_track/modules/work_orders/data/geolocator_location_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sonda: rota inicial e GPS real do device', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    final textos = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    debugPrint('[PROBE] tela inicial: $textos');

    final inicio = DateTime.now();
    final resultado = await GeolocatorLocationService().getCurrentLocation();
    final ms = DateTime.now().difference(inicio).inMilliseconds;

    switch (resultado) {
      case Success(:final value):
        debugPrint(
          '[PROBE] GPS OK em ${ms}ms '
          '(lat=${value.latitude}, lon=${value.longitude})',
        );
      case Failure(:final value):
        debugPrint(
          '[PROBE] GPS FALHOU em ${ms}ms: '
          '${value.code} / ${value.message}',
        );
    }
  });
}
