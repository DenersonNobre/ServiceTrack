// Testes unitários e de widget para AppFeedback e tokens de alvo tátil (UC-06.02).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/app/theme/app_colors.dart';
import 'package:service_track/core/ui/.index.dart';

void main() {
  group('app_touch_target tokens', () {
    test('garantem alvo tátil mínimo de 48dp conforme Styleguide v2.1', () {
      expect(kMinTouchTargetEdge, greaterThanOrEqualTo(48.0));
      expect(kMinTouchTargetSize.width, greaterThanOrEqualTo(48.0));
      expect(kMinTouchTargetSize.height, greaterThanOrEqualTo(48.0));
      expect(kMinTouchTargetHeight.height, greaterThanOrEqualTo(48.0));
      expect(kMinTouchTargetConstraints.minWidth, greaterThanOrEqualTo(48.0));
      expect(kMinTouchTargetConstraints.minHeight, greaterThanOrEqualTo(48.0));
    });
  });

  group('AppFeedback', () {
    testWidgets('showError exibe SnackBar com AppColors.error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppFeedback.showError(context, 'Falha de teste'),
                child: const Text('disparar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('disparar'));
      await tester.pump();

      expect(find.text('Falha de teste'), findsOneWidget);
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, AppColors.error);
    });

    testWidgets('showSuccess exibe SnackBar com AppColors.primaryAction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppFeedback.showSuccess(context, 'Salvo com sucesso'),
                child: const Text('disparar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('disparar'));
      await tester.pump();

      expect(find.text('Salvo com sucesso'), findsOneWidget);
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, AppColors.primaryAction);
    });

    testWidgets('showInfo exibe SnackBar com AppColors.gray900', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppFeedback.showInfo(context, 'Aviso neutro'),
                child: const Text('disparar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('disparar'));
      await tester.pump();

      expect(find.text('Aviso neutro'), findsOneWidget);
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, AppColors.gray900);
    });
  });
}
