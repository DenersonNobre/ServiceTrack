import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/checklists/.index.dart';

void main() {
  testWidgets('UC-04.02 - ChecklistItemWidget garante alvos >= 48dp e expande observacao',
      (tester) async {
    ChecklistAnswerStatus? current;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ChecklistItemWidget(
                title: 'Verificar dreno',
                selectedStatus: current,
                onStatusChanged: (s) => setState(() => current = s),
              );
            },
          ),
        ),
      ),
    );

    for (final key in const [
      Key('checklist-btn-conforme'),
      Key('checklist-btn-nao-conforme'),
      Key('checklist-btn-nao-aplica'),
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    expect(find.byKey(const Key('checklist-notes-field')), findsNothing);

    await tester.tap(find.byKey(const Key('checklist-btn-nao-conforme')));
    await tester.pumpAndSettle();

    expect(current, ChecklistAnswerStatus.naoConforme);
    expect(find.byKey(const Key('checklist-notes-field')), findsOneWidget);
  });
}
