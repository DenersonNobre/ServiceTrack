import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/profile/data/memory_technician_profile_repository.dart';
import 'package:service_track/modules/profile/ui/profile_routes.dart';

void main() {
  testWidgets(
    'OPS-APP-SHELL-ROUTES - rota de perfil monta escopo Kortex e renderiza',
    (tester) async {
      final routes = ProfileRoutes(
        profileRepository: MemoryTechnicianProfileRepository(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open-profile'),
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
      await tester.tap(find.byKey(const Key('open-profile')));
      await tester.pumpAndSettle();

      expect(find.text('Perfil Comercial'), findsOneWidget);
    },
  );
}
