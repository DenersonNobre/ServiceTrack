import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/core/ui/dismissible_tile.dart';

void main() {
  testWidgets('DismissibleTile exibe child e confirmação de dismiss', (
    tester,
  ) async {
    var confirmed = false;
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DismissibleTile(
            itemKey: const ValueKey('item-1'),
            onConfirmDismiss: () async {
              confirmed = true;
              return true;
            },
            onDismissed: () {
              dismissed = true;
            },
            confirmTitle: 'Excluir modelo?',
            confirmMessage: 'Deseja realmente excluir este item?',
            child: const ListTile(title: Text('Item de Teste')),
          ),
        ),
      ),
    );

    expect(find.text('Item de Teste'), findsOneWidget);

    // Arrasta para disparar dismiss
    await tester.drag(find.text('Item de Teste'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Diálogo de confirmação deve aparecer
    expect(find.text('Excluir modelo?'), findsOneWidget);
    expect(find.text('Deseja realmente excluir este item?'), findsOneWidget);

    // Clica em Excluir no diálogo (FilledButton)
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(dismissed, isTrue);
  });

  testWidgets('DismissibleTile cancela dismiss ao clicar em Cancelar', (
    tester,
  ) async {
    var dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DismissibleTile(
            itemKey: const ValueKey('item-2'),
            onDismissed: () {
              dismissed = true;
            },
            confirmTitle: 'Excluir modelo?',
            confirmMessage: 'Deseja realmente excluir este item?',
            child: const ListTile(title: Text('Item Cancelar')),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Item Cancelar'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Excluir modelo?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Item Cancelar'), findsOneWidget);
    expect(dismissed, isFalse);
  });
}
