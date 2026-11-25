// Rotas e bindings Kortex do módulo de home.
//
// SRP: compor a rota e widget escopados da tela inicial.
// Não implementa regra de negócio nem conhece o shell do app.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import '../../../core/ui/app_scoped_route.dart';
import '../../work_orders/data/work_order_sqlite_repository.dart';
import '../../work_orders/domain/ports/work_order_repository_port.dart';
import 'home_controller.dart';
import 'home_page.dart';

/// Bindings de navegação do módulo de home.
final class HomeRoutes {
  const HomeRoutes({required this.workOrderRepository});

  factory HomeRoutes.fromDatabase(SqliteProvider database) {
    return HomeRoutes(
      workOrderRepository: WorkOrderSqliteRepository(provider: database),
    );
  }

  final IWorkOrderRepositoryPort workOrderRepository;

  /// Rota para a tela principal (home).
  Route<void> home({
    required VoidCallback onProfile,
    required VoidCallback onCustomers,
    required VoidCallback onWorkOrders,
    required VoidCallback onNewWorkOrder,
    required VoidCallback onChecklists,
    required VoidCallback onSettings,
    VoidCallback? onSchedule,
  }) {
    return appScopedRoute<HomeController, void>(
      create: (_) => HomeController(repository: workOrderRepository),
      builder: (_, _) => HomePage(
        onProfile: onProfile,
        onCustomers: onCustomers,
        onWorkOrders: onWorkOrders,
        onNewWorkOrder: onNewWorkOrder,
        onChecklists: onChecklists,
        onSettings: onSettings,
        onSchedule: onSchedule,
      ),
    );
  }

  /// Widget raiz da Home com [KortexScope] para uso no shell inicial.
  Widget homeWidget({
    required VoidCallback onProfile,
    required VoidCallback onCustomers,
    required VoidCallback onWorkOrders,
    required VoidCallback onNewWorkOrder,
    required VoidCallback onChecklists,
    required VoidCallback onSettings,
    VoidCallback? onSchedule,
  }) {
    return KortexScope(
      providers: [
        KortexProvider<HomeController>(
          create: (_) => HomeController(repository: workOrderRepository),
          dispose: (controller) => controller.dispose(),
        ),
      ],
      child: HomePage(
        onProfile: onProfile,
        onCustomers: onCustomers,
        onWorkOrders: onWorkOrders,
        onNewWorkOrder: onNewWorkOrder,
        onChecklists: onChecklists,
        onSettings: onSettings,
        onSchedule: onSchedule,
      ),
    );
  }
}
