// Testes de widget para KortexMaterialApp e KortexCupertinoApp (TDD Red-Before-Green).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/core/ui/.index.dart';

final class _SampleService {
  const _SampleService(this.value);
  final String value;
}

void main() {
  group('KortexMaterialApp', () {
    testWidgets('provê instâncias injetadas via providers acessíveis por context.readKortex<T>()', (
      tester,
    ) async {
      await tester.pumpWidget(
        KortexMaterialApp(
          providers: [
            KortexProvider<_SampleService>(
              create: (_) => const _SampleService('material-ok'),
            ),
          ],
          app: MaterialApp(
            home: Builder(
              builder: (context) {
                final service = context.readKortex<_SampleService>();
                return Text(service.value);
              },
            ),
          ),
        ),
      );

      expect(find.text('material-ok'), findsOneWidget);
    });

    testWidgets('renderiza fielmente o MaterialApp passado (título, rotas, tema)', (
      tester,
    ) async {
      await tester.pumpWidget(
        KortexMaterialApp(
          providers: const [],
          app: MaterialApp(
            title: 'MaterialTestApp',
            theme: ThemeData.dark(),
            initialRoute: '/',
            routes: {
              '/': (context) => const Text('home-screen'),
              '/details': (context) => const Text('details-screen'),
            },
          ),
        ),
      );

      expect(find.text('home-screen'), findsOneWidget);
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'MaterialTestApp');
      expect(materialApp.theme?.brightness, Brightness.dark);
    });
  });

  group('KortexCupertinoApp', () {
    testWidgets('provê instâncias injetadas via providers acessíveis por context.readKortex<T>()', (
      tester,
    ) async {
      await tester.pumpWidget(
        KortexCupertinoApp(
          providers: [
            KortexProvider<_SampleService>(
              create: (_) => const _SampleService('cupertino-ok'),
            ),
          ],
          app: CupertinoApp(
            home: Builder(
              builder: (context) {
                final service = context.readKortex<_SampleService>();
                return Text(service.value);
              },
            ),
          ),
        ),
      );

      expect(find.text('cupertino-ok'), findsOneWidget);
    });

    testWidgets('renderiza fielmente o CupertinoApp passado', (tester) async {
      await tester.pumpWidget(
        const KortexCupertinoApp(
          providers: [],
          app: CupertinoApp(
            title: 'CupertinoTestApp',
            home: CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text('CupertinoNavTitle'),
              ),
              child: Center(child: Text('cupertino-body')),
            ),
          ),
        ),
      );

      expect(find.text('CupertinoNavTitle'), findsOneWidget);
      expect(find.text('cupertino-body'), findsOneWidget);
      final cupertinoApp = tester.widget<CupertinoApp>(find.byType(CupertinoApp));
      expect(cupertinoApp.title, 'CupertinoTestApp');
    });
  });
}
