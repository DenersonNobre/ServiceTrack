import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/app/adapters/checklist_proof_adapter.dart';
import 'package:service_track/modules/checklists/domain/entities/checklist_answer.dart';
import 'package:service_track/modules/checklists/domain/entities/checklist_template.dart';
import 'package:service_track/modules/checklists/domain/ports/checklist_answer_repository_port.dart';
import 'package:service_track/modules/checklists/domain/ports/checklist_template_repository_port.dart';

class _TplRepo implements IChecklistTemplateRepositoryPort {
  _TplRepo(this.tpl);
  final ChecklistTemplate? tpl;
  @override
  Future<IResult<ChecklistTemplate, ValidationError>> save(ChecklistTemplate template) async => Success(template);
  @override
  Future<IResult<List<ChecklistTemplate>, ValidationError>> findAll() async => const Success([]);
  @override
  Future<IResult<ChecklistTemplate?, ValidationError>> findById(String id) async => Success(tpl);
  @override
  Future<IResult<bool, ValidationError>> delete(String id) async => const Success(true);
}

class _AnsRepo implements IChecklistAnswerRepositoryPort {
  _AnsRepo(this.answers);
  final List<ChecklistAnswer> answers;
  @override
  Future<IResult<ChecklistAnswer, ValidationError>> save(ChecklistAnswer answer) async => Success(answer);
  @override
  Future<IResult<List<ChecklistAnswer>, ValidationError>> findByWorkOrder(String workOrderId) async => Success(answers);
}

void main() {
  test('UC-04.07 - prova real: sem template falha (fail-closed)', () async {
    final adapter = ChecklistProofAdapter(
      templateRepository: _TplRepo(null),
      answerRepository: _AnsRepo(const []),
    );
    final r = await adapter.getProof(workOrderId: 'wo1', templateId: null);
    expect(r.isFailure, isTrue);
    expect(r.getOrNullFailure()!.code, 'ERR_CHECKLIST_TEMPLATE_OBRIGATORIO');
  });

  test('UC-04.07 - política C: sem template permitido quando requireTemplate=false', () async {
    final adapter = ChecklistProofAdapter(
      templateRepository: _TplRepo(null),
      answerRepository: _AnsRepo(const []),
    );
    final r = await adapter.getProof(workOrderId: 'wo1', templateId: null, requireTemplate: false);
    expect(r.isSuccess, isTrue);
    expect(r.getOrNull()!.mandatoryTotal, 0);
  });

  test('UC-04.07 - prova real: template com obrigatório não respondido falha', () async {
    final tpl = ChecklistTemplate.tryCreate(id: 't1', title: 'T', items: [
      ChecklistItem.tryCreate(id: 'i1', title: 'Item 1', isRequired: true, order: 0).getOrNull()!,
      ChecklistItem.tryCreate(id: 'i2', title: 'Item 2', isRequired: false, order: 1).getOrNull()!,
    ]).getOrNull()!;
    final adapter = ChecklistProofAdapter(templateRepository: _TplRepo(tpl), answerRepository: _AnsRepo(const []));
    final r = await adapter.getProof(workOrderId: 'wo1', templateId: 't1');
    expect(r.isFailure, isTrue);
    expect(r.getOrNullFailure()!.code, 'ERR_CHECKLIST_INCOMPLETO');
  });

  test('UC-04.07 - prova real: obrigatório respondido passa', () async {
    final tpl = ChecklistTemplate.tryCreate(id: 't1', title: 'T', items: [
      ChecklistItem.tryCreate(id: 'i1', title: 'Item 1', isRequired: true, order: 0).getOrNull()!,
    ]).getOrNull()!;
    final ans = ChecklistAnswer.tryCreate(
      workOrderId: 'wo1', itemId: 'i1', status: ChecklistAnswerStatus.conforme,
    ).getOrNull()!;
    final adapter = ChecklistProofAdapter(templateRepository: _TplRepo(tpl), answerRepository: _AnsRepo([ans]));
    final r = await adapter.getProof(workOrderId: 'wo1', templateId: 't1');
    expect(r.isSuccess, isTrue);
    expect(r.getOrNull()!.mandatoryTotal, 1);
    expect(r.getOrNull()!.answeredMandatory, 1);
  });
}