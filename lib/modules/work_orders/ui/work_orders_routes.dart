// Rotas e bindings Kortex do módulo de Ordens de Serviço.
//
// SRP: compor rotas escopadas de OS e execução de checklist.
// Não implementa regra de negócio nem conhece o shell do app.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/app_scoped_route.dart';
import '../../checklists/domain/ports/checklist_answer_repository_port.dart';
import '../../checklists/domain/ports/checklist_template_repository_port.dart';
import '../../checklists/ui/checklists_routes.dart';
import '../../checklists/ui/execution/checklist_execution_controller.dart';
import '../../checklists/ui/execution/checklist_execution_page.dart';
import '../../customers/domain/ports/customer_repository_port.dart';
import '../../settings/domain/.index.dart';
import '../../settings/features/.index.dart';
import '../domain/ports/checklist_proof_port.dart';
import '../domain/ports/location_service_port.dart';
import '../domain/ports/work_order_repository_port.dart';
import '../domain/value_objects/work_order_status.dart';
import 'form/work_order_form_controller.dart';
import 'form/work_order_form_page.dart';
import 'list/work_order_list_controller.dart';
import 'list/work_order_list_page.dart';

/// Bindings de navegação do bounded context de Ordens de Serviço.
final class WorkOrdersRoutes {
  const WorkOrdersRoutes({
    required this.workOrderRepository,
    required this.customerRepository,
    required this.locationService,
    required this.checklistProofPort,
    required this.checklistTemplateRepository,
    required this.checklistAnswerRepository,
    required this.settingsRepository,
  });

  final IWorkOrderRepositoryPort workOrderRepository;
  final ICustomerRepositoryPort customerRepository;
  final ILocationServicePort locationService;
  final IChecklistProofPort checklistProofPort;
  final IChecklistTemplateRepositoryPort checklistTemplateRepository;
  final IChecklistAnswerRepositoryPort checklistAnswerRepository;
  final ISettingsRepositoryPort settingsRepository;

  /// Lista de OS com atalhos para cadastro, checklist e laudo.
  Route<void> list({void Function(String workOrderId)? onReport}) {
    return appScopedRoute<WorkOrderListController, void>(
      create: (_) => WorkOrderListController(
        repository: workOrderRepository,
        locationService: locationService,
        checklistProofPort: checklistProofPort,
        getSettings: GetSettings(repository: settingsRepository),
      ),
      builder: (context, controller) => WorkOrderListPage(
        onAdd: () => _push(context, form(onSaved: controller.load)),
        onTemplates: () => _push(
          context,
          ChecklistsRoutes(templateRepository: checklistTemplateRepository)
              .list(),
        ),
        onChecklist: (workOrderId, templateId) => _push(
          context,
          checklistExecution(workOrderId: workOrderId, templateId: templateId),
        ),
        onReport: onReport,
      ),
    );
  }

  /// Cadastro de OS; ao salvar, fecha a rota e notifica o chamador.
  Route<void> form({VoidCallback? onSaved}) {
    return appScopedRoute<WorkOrderFormController, void>(
      create: (_) => WorkOrderFormController(
        repository: workOrderRepository,
        customerRepository: customerRepository,
        checklistTemplateRepository: checklistTemplateRepository,
      ),
      builder: (context, _) => WorkOrderFormPage(
        onSaved: () {
          Navigator.of(context).pop();
          onSaved?.call();
        },
      ),
    );
  }

  /// Execução do checklist vinculado à OS.
  Route<void> checklistExecution({
    required String workOrderId,
    required String templateId,
  }) {
    return appScopedRoute<ChecklistExecutionController, void>(
      create: (_) => ChecklistExecutionController(
        templateRepository: checklistTemplateRepository,
        answerRepository: checklistAnswerRepository,
        workOrderId: workOrderId,
        templateId: templateId,
        isWorkOrderMutable: () => _isWorkOrderMutable(workOrderId),
      ),
      builder: (_, _) => const ChecklistExecutionPage(),
    );
  }

  Future<bool> _isWorkOrderMutable(String workOrderId) async {
    final result = await workOrderRepository.findAll();
    switch (result) {
      case Success(:final value):
        final workOrder = value
            .where((candidate) => candidate.id == workOrderId)
            .firstOrNull;
        return workOrder != null &&
            workOrder.status != WorkOrderStatus.completed &&
            workOrder.status != WorkOrderStatus.cancelled;
      case Failure():
        return false;
    }
  }

  void _push(BuildContext context, Route<void> route) {
    // ignore: discarded_futures
    Navigator.of(context).push(route);
  }
}
