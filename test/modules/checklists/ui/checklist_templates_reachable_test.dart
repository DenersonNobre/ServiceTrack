// Teste de alcançabilidade do cadastro de modelos (UC-04.09).
//
// SRP: provar que a lista de modelos deixou de ser código morto — a rota é
// montada pela lista de OS, o cadastro cria um modelo real e esse modelo fica
// disponível no seletor do formulário de OS. Sem isso, `template→OS→checklist`
// continua inalcançável mesmo com a página existindo.

import 'dart:async';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/checklists/.index.dart';
import 'package:service_track/modules/customers/data/memory_customer_repository.dart';
import 'package:service_track/modules/settings/.index.dart';
import 'package:service_track/modules/work_orders/data/memory_work_order_repository.dart';
import 'package:service_track/modules/work_orders/domain/ports/checklist_proof_port.dart';
import 'package:service_track/modules/work_orders/domain/ports/location_service_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/checklist_completion_proof.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';
import 'package:service_track/modules/work_orders/ui/work_orders_routes.dart';

final class _FakeLocationService implements ILocationServicePort {
  @override
  Future<IResult<GeoPoint, ValidationError>> getCurrentLocation() async =>
      const Failure(ValidationError(code: 'ERR_FAKE', message: 'fake'));
}

final class _FakeChecklistProofPort implements IChecklistProofPort {
  @override
  Future<IResult<ChecklistCompletionProof, ValidationError>> getProof({
    required String workOrderId,
    required String? templateId,
    bool requireTemplate = true,
  }) async => const Failure(ValidationError(code: 'ERR_FAKE', message: 'fake'));
}

WorkOrdersRoutes _routes(IChecklistTemplateRepositoryPort templateRepository) =>
    WorkOrdersRoutes(
      workOrderRepository: MemoryWorkOrderRepository(),
      customerRepository: MemoryCustomerRepository(),
      locationService: _FakeLocationService(),
      checklistProofPort: _FakeChecklistProofPort(),
      checklistTemplateRepository: templateRepository,
      checklistAnswerRepository: MemoryChecklistAnswerRepository(),
      settingsRepository: MemorySettingsRepository(),
    );

Widget _host(WorkOrdersRoutes routes) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('open-work-orders'),
          onPressed: () => unawaited(Navigator.of(context).push(routes.list())),
          child: const Text('Abrir'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('UC-04.09 - lista de OS abre a lista de modelos de checklist', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_routes(MemoryChecklistTemplateRepository())),
    );

    await tester.tap(find.byKey(const Key('open-work-orders')));
    await tester.pumpAndSettle();
    expect(find.text('Ordens de Serviço'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wo-templates')));
    await tester.pumpAndSettle();

    expect(
      find.text('Modelos de Checklist'),
      findsOneWidget,
      reason: 'a página existia sem rota; agora precisa ser alcançável',
    );
    expect(find.byKey(const Key('checklist-template-add')), findsOneWidget);
  });

  testWidgets('UC-04.09 - modelo criado pela rota aparece no seletor da OS', (
    tester,
  ) async {
    final templateRepository = MemoryChecklistTemplateRepository();
    final routes = _routes(templateRepository);

    await tester.pumpWidget(_host(routes));
    await tester.tap(find.byKey(const Key('open-work-orders')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wo-templates')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('checklist-template-add')));
    await tester.pumpAndSettle();
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

    expect(
      find.text('Instalação Split'),
      findsOneWidget,
      reason: 'ao salvar, volta para a lista já com o modelo persistido',
    );

    final persisted = (await templateRepository.findAll()).getOrNull()!;
    expect(persisted, hasLength(1));

    // Volta para a lista de OS e abre o formulário: o seletor precisa oferecer
    // o modelo recém-criado, senão `checklistTemplateId` nunca sai de null.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wo-add')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('wo-checklist-template')));
    await tester.pumpAndSettle();

    expect(
      find.text('Instalação Split'),
      findsWidgets,
      reason: 'modelo persistido tem de aparecer no dropdown da OS',
    );
  });
}
