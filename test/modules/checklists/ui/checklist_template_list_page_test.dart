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

  testWidgets('UC-04.01 - tocar em um item dispara onSelect', (tester) async {
    final repo = MemoryChecklistTemplateRepository();
    final i1 = ChecklistItem.tryCreate(id: 'i1', title: 'Item 1').getOrNull()!;
    final tpl = ChecklistTemplate.tryCreate(
      id: 't1',
      title: 'Manutenção Preventiva',
      items: [i1],
    ).getOrNull()!;
    await repo.save(tpl);

    ChecklistTemplate? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: KortexScope(
          providers: [
            KortexProvider<ChecklistTemplateListController>(
              create: (_) => ChecklistTemplateListController(repository: repo),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: ChecklistTemplateListPage(
            onSelect: (item) => selected = item,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manutenção Preventiva'));
    await tester.pump();

    expect(selected, isNotNull);
    expect(selected!.id, 't1');
    expect(selected!.title, 'Manutenção Preventiva');
  });

  testWidgets('UC-04.01 - swipe para excluir modelo exibe diálogo e remove item', (
    tester,
  ) async {
    final repo = MemoryChecklistTemplateRepository();
    final i1 = ChecklistItem.tryCreate(id: 'i1', title: 'Item 1').getOrNull()!;
    final tpl = ChecklistTemplate.tryCreate(
      id: 't1',
      title: 'Modelo para Excluir',
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

    expect(find.text('Modelo para Excluir'), findsOneWidget);

    // Arrasta para a esquerda para disparar swipe dismiss
    await tester.drag(find.text('Modelo para Excluir'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Diálogo de confirmação deve aparecer
    expect(find.text('Excluir modelo?'), findsOneWidget);
    expect(
      find.text('Deseja realmente excluir o modelo "Modelo para Excluir"?'),
      findsOneWidget,
    );

    // Clica em Excluir
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    // Item não deve mais estar na tela e feedback de sucesso exibido
    expect(find.text('Modelo para Excluir'), findsNothing);
    expect(find.text('Modelo excluído com sucesso'), findsOneWidget);
    expect(find.text('Nenhum modelo cadastrado'), findsOneWidget);
  });
}
