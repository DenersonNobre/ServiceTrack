// Controller de execução de checklist por OS (UC-04.02/04.06/04.07).
//
// SRP: carregar template+respostas e persistir respostas. Não renderiza UI.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../domain/entities/checklist_answer.dart';
import '../../domain/entities/checklist_template.dart';
import '../../domain/ports/checklist_answer_repository_port.dart';
import '../../domain/ports/checklist_template_repository_port.dart';

final class ChecklistExecutionController extends IKortexController {
  ChecklistExecutionController({
    required this.templateRepository,
    required this.answerRepository,
    required this.workOrderId,
    required this.templateId,
  });

  final IChecklistTemplateRepositoryPort templateRepository;
  final IChecklistAnswerRepositoryPort answerRepository;
  final String workOrderId;
  final String templateId;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  final KortexSignal<ChecklistTemplate?> template =
      KortexSignal<ChecklistTemplate?>(null);
  final KortexSignal<Map<String, ChecklistAnswer>> answers =
      KortexSignal<Map<String, ChecklistAnswer>>({});
  final KortexSignal<String?> savingItemId = KortexSignal<String?>(null);
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final tplR = await templateRepository.findById(templateId);
    if (tplR case Failure(:final value)) {
      loading.value = false;
      error.value = value.message;
      return;
    }
    template.value = tplR.getOrNull();
    final ansR = await answerRepository.findByWorkOrder(workOrderId);
    loading.value = false;
    switch (ansR) {
      case Failure(:final value):
        error.value = value.message;
      case Success(:final value):
        answers.value = {for (final a in value) a.itemId: a};
    }
  }

  Future<IResult<ChecklistAnswer, ValidationError>> setAnswer({
    required String itemId,
    required ChecklistAnswerStatus status,
    String notes = '',
  }) async {
    savingItemId.value = itemId;
    final result = ChecklistAnswer.tryCreate(
      workOrderId: workOrderId,
      itemId: itemId,
      status: status,
      notes: notes,
    );
    switch (result) {
      case Failure(:final value):
        savingItemId.value = null;
        return Failure(value);
      case Success(:final value):
        final saved = await answerRepository.save(value);
        savingItemId.value = null;
        if (saved case Success(:final value)) {
          answers.value = {...answers.value, itemId: value};
        }
        return saved;
    }
  }

  @override
  void onDispose() {
    loading.dispose();
    error.dispose();
    template.dispose();
    answers.dispose();
    savingItemId.dispose();
  }
}
