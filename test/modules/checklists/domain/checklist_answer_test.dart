import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/checklists/.index.dart';

void main() {
  group('UC-04.02 - ChecklistAnswer & Completude (INV-03 / INV-06)', () {
    test('aceita resposta CONFORME em OS mutavel (IN_PROGRESS)', () {
      final result = ChecklistAnswer.tryCreate(
        workOrderId: 'os-1',
        itemId: 'i1',
        status: ChecklistAnswerStatus.conforme,
      );
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()?.status, ChecklistAnswerStatus.conforme);
    });

    test('rejeita resposta em OS imutavel (COMPLETED) com ERR_OS_IMUTAVEL', () {
      final result = ChecklistAnswer.tryCreate(
        workOrderId: 'os-1',
        itemId: 'i1',
        status: ChecklistAnswerStatus.conforme,
        isWorkOrderMutable: false,
      );
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, 'ERR_OS_IMUTAVEL');
    });

    test('aceita NAO_CONFORME com observacao tecnica', () {
      final result = ChecklistAnswer.tryCreate(
        workOrderId: 'os-1',
        itemId: 'i1',
        status: ChecklistAnswerStatus.naoConforme,
        notes: 'Dreno obstruído',
      );
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()?.notes, 'Dreno obstruído');
    });

    test('validateChecklistCompleteness rejeita item obrigatorio pendente (INV-03)', () {
      final i1 = ChecklistItem.tryCreate(id: 'i1', title: 'Item 1', isRequired: true).getOrNull()!;
      final i2 = ChecklistItem.tryCreate(id: 'i2', title: 'Item 2', isRequired: true).getOrNull()!;
      final tpl = ChecklistTemplate.tryCreate(
        id: 'tpl-1',
        title: 'Vistoria',
        items: [i1, i2],
      ).getOrNull()!;
      final a1 = ChecklistAnswer.tryCreate(
        workOrderId: 'os-1',
        itemId: 'i1',
        status: ChecklistAnswerStatus.conforme,
      ).getOrNull()!;

      final incomplete = validateChecklistCompleteness(template: tpl, answers: [a1]);
      expect(incomplete.isFailure, isTrue);
      expect(incomplete.getOrNullFailure()?.code, 'ERR_CHECKLIST_INCOMPLETO');

      final a2 = ChecklistAnswer.tryCreate(
        workOrderId: 'os-1',
        itemId: 'i2',
        status: ChecklistAnswerStatus.naoAplica,
      ).getOrNull()!;
      final complete = validateChecklistCompleteness(template: tpl, answers: [a1, a2]);
      expect(complete.isSuccess, isTrue);
    });
  });
}
