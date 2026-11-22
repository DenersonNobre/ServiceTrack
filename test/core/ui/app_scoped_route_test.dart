// Testes de widget para appScopedRoute (escopo Kortex + auto-dispose + retorno tipado).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/core/ui/.index.dart';

final class _FakeController extends IKortexController {
  _FakeController(this.label);
  final String label;
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

void main() {
  testWidgets(
    'appScopedRoute fornece controller no KortexScope, retorna valor e faz auto-dispose no pop',
    (tester) async {
      late _FakeController created;
      String? poppedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  poppedResult = await Navigator.of(context).push<String>(
                    appScopedRoute<_FakeController, String>(
                      create: (_) {
                        created = _FakeController('ok-kortex');
                        return created;
                      },
                      builder: (ctx, controller) => Scaffold(
                        body: Column(
                          children: [
                            Text(controller.label),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop('concluido'),
                              child: const Text('voltar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('ok-kortex'), findsOneWidget);
      expect(created.disposed, isFalse);

      await tester.tap(find.text('voltar'));
      await tester.pumpAndSettle();

      expect(poppedResult, 'concluido');
      expect(created.disposed, isTrue);
    },
  );
}
