// Testes do formulário de cadastro de modelo de checklist (UC-04.09).
//
// SRP: provar que a tela cadastra um modelo pela UI, mostra o erro de domínio
// quando inválido e não troca o texto de um item ao remover o vizinho.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:service_track/modules/checklists/.index.dart';

Widget _host({
  required ChecklistTemplateFormController controller,
  VoidCallback? onSaved,
}) => MaterialApp(
  home: KortexScope(
    providers: [
      KortexProvider<ChecklistTemplateFormController>(
        create: (_) => controller,
        dispose: (c) => c.dispose(),
      ),
    ],
    child: ChecklistTemplateFormPage(onSaved: onSaved),
  ),
);

void main() {
  testWidgets('UC-04.09 - cadastra modelo pela UI e notifica a lista', (
    tester,
  ) async {
    final repo = MemoryChecklistTemplateRepository();
    final controller = ChecklistTemplateFormController(repository: repo);
    var savedCallbacks = 0;

    await tester.pumpWidget(
      _host(controller: controller, onSaved: () => savedCallbacks++),
    );

    await tester.enterText(
      find.byKey(const Key('checklist-template-title')),
      'Instalação Split',
    );
    await tester.tap(find.byKey(const Key('checklist-template-add-item')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('checklist-template-item-0')),
      'Conferir infraestrutura',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('checklist-template-save')));
    await tester.pumpAndSettle();

    expect(savedCallbacks, 1);
    final persisted = (await repo.findAll()).getOrNull()!;
    expect(persisted, hasLength(1));
    expect(persisted.single.title, 'Instalação Split');
    expect(persisted.single.items.map((item) => item.title), <String>[
      'Conferir infraestrutura',
    ]);
  });

  testWidgets('UC-04.09 - modelo sem itens mostra erro do domínio', (
    tester,
  ) async {
    final repo = MemoryChecklistTemplateRepository();
    final controller = ChecklistTemplateFormController(repository: repo);

    await tester.pumpWidget(_host(controller: controller));

    await tester.enterText(
      find.byKey(const Key('checklist-template-title')),
      'Vistoria Rápida',
    );
    await tester.tap(find.byKey(const Key('checklist-template-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('O checklist precisa ter pelo menos um item.'),
      findsOneWidget,
    );
    expect((await repo.findAll()).getOrNull(), isEmpty);
  });

  testWidgets('UC-04.09 - remover item preserva o texto do item seguinte', (
    tester,
  ) async {
    final repo = MemoryChecklistTemplateRepository();
    final controller = ChecklistTemplateFormController(repository: repo);

    await tester.pumpWidget(_host(controller: controller));

    await tester.tap(find.byKey(const Key('checklist-template-add-item')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('checklist-template-item-0')),
      'Primeiro item',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('checklist-template-add-item')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('checklist-template-item-1')),
      'Segundo item',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('checklist-template-item-remove-0')));
    await tester.pumpAndSettle();

    expect(find.text('Primeiro item'), findsNothing);
    expect(
      find.text('Segundo item'),
      findsOneWidget,
      reason: 'identidade por rascunho evita herdar texto do vizinho removido',
    );
  });

  testWidgets('UC-04.09 - botão de remover item está configurado como suffixIcon', (
    tester,
  ) async {
    final repo = MemoryChecklistTemplateRepository();
    final controller = ChecklistTemplateFormController(repository: repo);

    await tester.pumpWidget(_host(controller: controller));
    await tester.tap(find.byKey(const Key('checklist-template-add-item')));
    await tester.pump();

    final removeFinder = find.byKey(
      const Key('checklist-template-item-remove-0'),
    );
    expect(removeFinder, findsOneWidget);

    final icon = tester.widget<Icon>(
      find.descendant(of: removeFinder, matching: find.byType(Icon)),
    );
    expect(icon.icon, Icons.delete_outline);
    expect(icon.color, const Color(0xFF991B1B)); // AppColors.error
  });
}
