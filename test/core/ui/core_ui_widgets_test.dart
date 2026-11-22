import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/app/theme/app_colors.dart';
import 'package:service_track/core/.index.dart';

void main() {
  group('Core UI (Styleguide v2.1)', () {
    testWidgets('AppPrimaryButton respeita 48dp, icone, disabled e loading com contraste',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPrimaryButton(
              label: 'Salvar',
              icon: Icons.check,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(AppPrimaryButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('Salvar'));
      expect(taps, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPrimaryButton(
              label: 'Salvar',
              loading: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        btn.style?.backgroundColor?.resolve({WidgetState.disabled}),
        AppColors.primaryAction,
      );
      await tester.tap(find.byType(AppPrimaryButton));
      expect(taps, 1);
    });

    testWidgets('AppStatusBadge aplica tokens de cor e raio 24px nas 4 variantes',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppStatusBadge(label: 'Concluída', tone: AppStatusTone.success),
                AppStatusBadge(label: 'Agendada', tone: AppStatusTone.info),
                AppStatusBadge(label: 'Em curso', tone: AppStatusTone.warning),
                AppStatusBadge(label: 'Cancelada', tone: AppStatusTone.error),
              ],
            ),
          ),
        ),
      );

      final boxes = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((w) => w.decoration as BoxDecoration)
          .toList();
      expect(boxes.length, 4);
      expect(boxes[0].color, const Color(0xFFEBF8F0));
      expect(boxes[1].color, const Color(0xFFEBF5FF));
      expect(boxes[2].color, const Color(0xFFFEF8E7));
      expect(boxes[3].color, const Color(0xFFFEEFEF));
      for (final b in boxes) {
        expect(b.borderRadius, BorderRadius.circular(24));
      }
    });

    testWidgets('AppEmptyState exibe icone, titulo, mensagem e suporta com/sem CTA',
        (tester) async {
      var clicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Nenhuma visita',
              message: 'Crie sua primeira ordem de serviço.',
              actionLabel: 'Nova OS',
              onAction: () => clicked = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(find.text('Nenhuma visita'), findsOneWidget);
      expect(find.text('Crie sua primeira ordem de serviço.'), findsOneWidget);
      await tester.tap(find.text('Nova OS'));
      expect(clicked, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Vazio',
              message: 'Sem registros.',
            ),
          ),
        ),
      );
      expect(find.byType(AppPrimaryButton), findsNothing);
    });
  });
}
