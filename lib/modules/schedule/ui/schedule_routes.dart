// Rotas e bindings Kortex do módulo de Agenda / Calendário.
//
// SRP: compor rotas escopadas da Agenda. Não implementa regra de negócio
// nem conhece o shell do app.

import 'package:flutter/material.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import '../../../core/ui/app_scoped_route.dart';
import '../../work_orders/data/work_order_sqlite_repository.dart';
import '../../work_orders/domain/ports/work_order_repository_port.dart';
import 'schedule_controller.dart';
import 'schedule_page.dart';

/// Bindings de navegação do módulo de Agenda.
final class ScheduleRoutes {
  const ScheduleRoutes({required this.repository});

  /// Constrói as rotas injetando o repositório SQLite de Ordens de Serviço.
  factory ScheduleRoutes.fromDatabase(SqliteProvider database) {
    return ScheduleRoutes(
      repository: WorkOrderSqliteRepository(provider: database),
    );
  }

  final IWorkOrderRepositoryPort repository;

  /// Retorna a rota escopada da página de Agenda.
  Route<void> schedule({
    void Function(String workOrderId)? onWorkOrderTapped,
  }) {
    return appScopedRoute<ScheduleController, void>(
      create: (_) => ScheduleController(repository: repository),
      builder: (_, _) => SchedulePage(onWorkOrderTapped: onWorkOrderTapped),
    );
  }
}
