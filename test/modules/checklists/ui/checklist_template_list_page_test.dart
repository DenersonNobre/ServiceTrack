import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/checklists/.index.dart';

void main() {
  testWidgets('UC-04.01 - ChecklistTemplateListPage exibe vazio e lista itens',
      (tester) async {
    final repo = MemoryChecklistTemplateRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<ChecklistTemplateListController>(
              create: (_) => ChecklistTemplateListController(repository: repo),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const ChecklistTemplateListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhum modelo cadastrado'), findsOneWidget);

    final i1 = ChecklistItem.tryCreate(id: 'i1', title: 'Item 1').getOrNull()!;
    final tpl = ChecklistTemplate.tryCreate(
      id: 't1',
      title: 'Manutenção Preventiva',
      items: [i1],
    ).getOrNull()!;
    await repo.save(tpl);

    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<ChecklistTemplateListController>(
              create: (_) => ChecklistTemplateListController(repository: repo),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const ChecklistTemplateListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Manutenção Preventiva'), findsOneWidget);
    expect(find.text('1 item(ns)'), findsOneWidget);
  });
}
