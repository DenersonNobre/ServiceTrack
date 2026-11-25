// Rotas e bindings Kortex do módulo de checklists (UC-04.09).
//
// SRP: compor rotas de listagem e cadastro de modelos de checklist.
// Não implementa regra de negócio nem conhece o shell do app.

import 'package:flutter/material.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import '../../../core/ui/app_scoped_route.dart';
import '../data/checklist_template_sqlite_repository.dart';
import '../domain/entities/checklist_template.dart';
import '../domain/ports/checklist_template_repository_port.dart';
import 'templates/checklist_template_form_controller.dart';
import 'templates/checklist_template_form_page.dart';
import 'templates/checklist_template_list_controller.dart';
import 'templates/checklist_template_list_page.dart';

/// Bindings de navegação do bounded context de checklists.
final class ChecklistsRoutes {
  /// Cria as rotas sobre a porta de modelos.
  const ChecklistsRoutes({required this.templateRepository});

  factory ChecklistsRoutes.fromDatabase(SqliteProvider database) {
    return ChecklistsRoutes(
      templateRepository: ChecklistTemplateSqliteRepository(provider: database),
    );
  }

  /// Porta de persistência de modelos de checklist.
  final IChecklistTemplateRepositoryPort templateRepository;

  /// Lista de modelos com atalho para cadastro.
  Route<void> list() {
    return appScopedRoute<ChecklistTemplateListController, void>(
      create: (_) =>
          ChecklistTemplateListController(repository: templateRepository),
      builder: (context, controller) => ChecklistTemplateListPage(
        onAdd: () => _push(context, form(onSaved: controller.load)),
        onSelect: (template) => _push(
          context,
          form(initialTemplate: template, onSaved: controller.load),
        ),
      ),
    );
  }

  /// Cadastro de modelo; ao salvar, fecha a rota e notifica o chamador.
  Route<void> form({ChecklistTemplate? initialTemplate, VoidCallback? onSaved}) {
    return appScopedRoute<ChecklistTemplateFormController, void>(
      create: (_) => ChecklistTemplateFormController(
        repository: templateRepository,
        initialTemplate: initialTemplate,
      ),
      builder: (context, _) => ChecklistTemplateFormPage(
        onSaved: () {
          Navigator.of(context).pop();
          onSaved?.call();
        },
      ),
    );
  }

  void _push(BuildContext context, Route<void> route) {
    // ignore: discarded_futures
    Navigator.of(context).push(route);
  }
}
