// Testes de rotas e navegação de checklists (UC-04.01 / UC-04.09).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/checklists/.index.dart';

void main() {
  group('ChecklistsRoutes', () {
    testWidgets('list() navega para form() ao selecionar template', (tester) async {
      final repo = MemoryChecklistTemplateRepository();
      final item = ChecklistItem.tryCreate(id: 'i1', title: 'Item 1').getOrNull()!;
      final template = ChecklistTemplate.tryCreate(
        id: 't1',
        title: 'Modelo para Edição',
        items: [item],
      ).getOrNull()!;
      await repo.save(template);

      final routes = ChecklistsRoutes(templateRepository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(routes.list()),
                  child: const Text('Abrir Lista'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Lista'));
      await tester.pumpAndSettle();

      expect(find.text('Modelos de Checklist'), findsOneWidget);
      expect(find.text('Modelo para Edição'), findsOneWidget);

      // Toca no modelo para abrir a tela de edição
      await tester.tap(find.text('Modelo para Edição'));
      await tester.pumpAndSettle();

      // Deve estar na tela de edição
      expect(find.text('Editar modelo'), findsOneWidget);
      expect(find.text('Modelo para Edição'), findsWidgets);
      // O item aparece no TextFormField (label "Item 1" e valor "Item 1")
      expect(find.text('Item 1'), findsWidgets);
    });
  });
}
