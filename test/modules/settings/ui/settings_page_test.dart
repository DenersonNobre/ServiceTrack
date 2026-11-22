import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/settings/.index.dart';

void main() {
  testWidgets(
    'UC-07.02 - página de configurações renderiza defaults e persiste toggle',
    (tester) async {
      final repository = MemorySettingsRepository();
      final routes = SettingsRoutes(settingsRepository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open-settings'),
                  onPressed: () {
                    unawaited(Navigator.of(context).push(routes.edit()));
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-settings')));
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
      final checklistTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('settings-require-checklist')),
      );
      final receiverTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('settings-require-receiver-document')),
      );
      expect(checklistTile.value, isTrue);
      expect(receiverTile.value, isFalse);
      expect(
        tester
            .getSize(find.byKey(const Key('settings-require-checklist')))
            .height,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(find.byKey(const Key('settings-require-checklist')));
      await tester.pumpAndSettle();

      expect(find.text('Configuração salva.'), findsOneWidget);
      expect(
        (await repository.load()).getOrNull()!.requireChecklistTemplate,
        isFalse,
      );
    },
  );
}
