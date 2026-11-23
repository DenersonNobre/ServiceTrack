// Testes do controller de cadastro de modelo de checklist (UC-04.09).
//
// SRP: provar que o cadastro delega a validação ao domínio (título/itens),
// normaliza itens em branco e persiste apenas modelos válidos.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/checklists/domain/entities/checklist_template.dart';
import 'package:service_track/modules/checklists/domain/ports/checklist_failure_codes.dart';
import 'package:service_track/modules/checklists/domain/ports/checklist_template_repository_port.dart';
import 'package:service_track/modules/checklists/ui/templates/checklist_template_form_controller.dart';

final class _MemoryTemplateRepository
    implements IChecklistTemplateRepositoryPort {
  final List<ChecklistTemplate> saved = <ChecklistTemplate>[];

  @override
  Future<IResult<ChecklistTemplate, ValidationError>> save(
    ChecklistTemplate template,
  ) async {
    saved.add(template);
    return Success(template);
  }

  @override
  Future<IResult<List<ChecklistTemplate>, ValidationError>> findAll() async =>
      Success(saved);

  @override
  Future<IResult<ChecklistTemplate?, ValidationError>> findById(
    String id,
  ) async => Success(saved.where((t) => t.id == id).firstOrNull);

  @override
  Future<IResult<bool, ValidationError>> delete(String id) async {
    saved.removeWhere((t) => t.id == id);
    return const Success(true);
  }
}

void main() {
  group('UC-04.09 - ChecklistTemplateFormController', () {
    late _MemoryTemplateRepository repository;
    late ChecklistTemplateFormController controller;

    setUp(() {
      repository = _MemoryTemplateRepository();
      controller = ChecklistTemplateFormController(repository: repository);
    });

    tearDown(() => controller.dispose());

    test('título vazio reprova com código do domínio e não persiste', () async {
      controller
        ..title.value = '   '
        ..addItem('Verificar pressão');

      await controller.save();

      expect(repository.saved, isEmpty);
      expect(controller.saved.value, isFalse);
      expect(controller.error.value, isNotNull);
      expect(
        controller.error.value,
        contains('título válido'),
        reason: 'mensagem vem de ChecklistFailureCodes.invalidTemplateTitle',
      );
    });

    test('sem itens preenchidos reprova com ERR_CHECKLIST_SEM_ITENS', () async {
      controller
        ..title.value = 'Instalação Split'
        ..addItem('   ');

      await controller.save();

      expect(repository.saved, isEmpty);
      expect(controller.saved.value, isFalse);
      expect(controller.lastFailureCode, ChecklistFailureCodes.emptyItems);
    });

    test(
      'modelo válido persiste com itens normalizados e ordem estável',
      () async {
        controller
          ..title.value = '  Vistoria   Rápida '
          ..addItem('Registrar estado geral')
          ..addItem('  ')
          ..addItem('Fotografar pendências');

        await controller.save();

        expect(controller.error.value, isNull);
        expect(controller.saved.value, isTrue);
        expect(repository.saved, hasLength(1));

        final persisted = repository.saved.single;
        expect(persisted.title, 'Vistoria Rápida');
        expect(persisted.items.map((item) => item.title), <String>[
          'Registrar estado geral',
          'Fotografar pendências',
        ], reason: 'item em branco é descartado, não vira item vazio');
        expect(persisted.items.map((item) => item.order), <int>[
          0,
          1,
        ], reason: 'ordem continua sequencial após descartar o branco');
      },
    );

    test('removeItem e updateItem mantêm o rascunho coerente', () {
      controller
        ..addItem('Primeiro')
        ..addItem('Segundo')
        ..updateItem(1, 'Segundo ajustado');

      expect(controller.itemDrafts.value.map((draft) => draft.title), <String>[
        'Primeiro',
        'Segundo ajustado',
      ]);

      final removedId = controller.itemDrafts.value.first.id;
      controller.removeItem(0);

      expect(controller.itemDrafts.value.map((draft) => draft.title), <String>[
        'Segundo ajustado',
      ]);
      expect(
        controller.itemDrafts.value.map((draft) => draft.id),
        isNot(contains(removedId)),
        reason: 'remoção descarta a identidade, sem reaproveitar o id',
      );
    });
  });
}
