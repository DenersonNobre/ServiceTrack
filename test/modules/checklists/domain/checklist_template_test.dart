import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/checklists/.index.dart';

void main() {
  group('UC-04.01 - ChecklistTemplate (Domain)', () {
    test('cria template valido com itens ordenados', () {
      final i2 = ChecklistItem.tryCreate(id: 'i2', title: 'Testar pressão', order: 2).getOrNull()!;
      final i1 = ChecklistItem.tryCreate(id: 'i1', title: 'Limpar filtro', order: 1).getOrNull()!;

      final result = ChecklistTemplate.tryCreate(
        id: 'tpl-1',
        title: 'Instalação Split',
        items: [i2, i1],
      );

      expect(result.isSuccess, isTrue);
      final tpl = result.getOrNull()!;
      expect(tpl.title, 'Instalação Split');
      expect(tpl.items.map((e) => e.id).toList(), ['i1', 'i2']);
    });

    test('rejeita titulo vazio com ERR_CHECKLIST_TITULO_INVALIDO', () {
      final i1 = ChecklistItem.tryCreate(id: 'i1', title: 'Item 1').getOrNull()!;
      final result = ChecklistTemplate.tryCreate(
        id: 'tpl-1',
        title: '   ',
        items: [i1],
      );

      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, 'ERR_CHECKLIST_TITULO_INVALIDO');
    });

    test('rejeita lista sem itens com ERR_CHECKLIST_SEM_ITENS', () {
      final result = ChecklistTemplate.tryCreate(
        id: 'tpl-1',
        title: 'Vistoria Rápida',
        items: const [],
      );

      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, 'ERR_CHECKLIST_SEM_ITENS');
    });

    test('rejeita itens com id duplicado com ERR_CHECKLIST_ITEM_ID_DUPLICADO', () {
      final a = ChecklistItem.tryCreate(id: 'dup', title: 'Item A').getOrNull()!;
      final b = ChecklistItem.tryCreate(id: 'dup', title: 'Item B').getOrNull()!;
      final result = ChecklistTemplate.tryCreate(
        id: 'tpl-1',
        title: 'Duplicado',
        items: [a, b],
      );

      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, 'ERR_CHECKLIST_ITEM_ID_DUPLICADO');
    });
  });
}
