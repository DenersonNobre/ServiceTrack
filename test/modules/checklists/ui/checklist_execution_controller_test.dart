import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/checklists/data/memory_checklist_answer_repository.dart';
import 'package:service_track/modules/checklists/data/memory_checklist_template_repository.dart';
import 'package:service_track/modules/checklists/domain/entities/checklist_answer.dart';
import 'package:service_track/modules/checklists/domain/entities/checklist_template.dart';
import 'package:service_track/modules/checklists/ui/execution/checklist_execution_controller.dart';

void main() {
  test('UC-04.07/INV-06 - bloqueia resposta quando OS imutável', () async {
    final tplRepo = MemoryChecklistTemplateRepository();
    final ansRepo = MemoryChecklistAnswerRepository();
    final tpl = ChecklistTemplate.tryCreate(id: 't1', title: 'T', items: [
      ChecklistItem.tryCreate(id: 'i1', title: 'Item', isRequired: true, order: 0).getOrNull()!,
    ]).getOrNull()!;
    await tplRepo.save(tpl);

    final c = ChecklistExecutionController(
      templateRepository: tplRepo,
      answerRepository: ansRepo,
      workOrderId: 'wo1',
      templateId: 't1',
      isWorkOrderMutable: () async => false,
    );
    await c.load();
    final r = await c.setAnswer(itemId: 'i1', status: ChecklistAnswerStatus.conforme);
    expect(r.isFailure, isTrue);
    expect(r.getOrNullFailure()!.code, 'ERR_OS_IMUTAVEL');
    final saved = await ansRepo.findByWorkOrder('wo1');
    expect(saved.getOrNull()!, isEmpty);
    c.dispose();
  });
}