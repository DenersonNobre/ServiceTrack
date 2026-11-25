// Gerador e roteador declarativo de páginas da aplicação ServiceTrack.

import 'package:flutter/material.dart';

import '../../modules/auth/ui/auth_routes.dart';
import '../../modules/checklists/ui/checklists_routes.dart';
import '../../modules/customers/ui/customers_routes.dart';
import '../../modules/home/ui/home_routes.dart';
import '../../modules/profile/ui/profile_routes.dart';
import '../../modules/settings/ui/settings_routes.dart';
import '../../modules/work_orders/ui/work_orders_routes.dart';
import '../app_gate.dart';
import '../app_services.dart';
import 'app_routes.dart';

/// Fabrica de rotas do aplicativo integrando os sub-módulos com o Navigator.
class AppPages {
  AppPages({
    required this.services,
    this.navigatorKey,
    AuthRoutes? authRoutes,
    HomeRoutes? homeRoutes,
    CustomersRoutes? customersRoutes,
    WorkOrdersRoutes? workOrdersRoutes,
    ProfileRoutes? profileRoutes,
    ChecklistsRoutes? checklistsRoutes,
    SettingsRoutes? settingsRoutes,
  })  : _authRoutes = authRoutes ?? AuthRoutes.fromServices(services),
        _initialHomeRoutes = homeRoutes,
        _initialCustomersRoutes = customersRoutes,
        _initialWorkOrdersRoutes = workOrdersRoutes,
        _initialProfileRoutes = profileRoutes,
        _initialChecklistsRoutes = checklistsRoutes,
        _initialSettingsRoutes = settingsRoutes {
    _initSubRoutes();
  }

  final AppServices services;
  final GlobalKey<NavigatorState>? navigatorKey;
  final AuthRoutes _authRoutes;
  final HomeRoutes? _initialHomeRoutes;
  final CustomersRoutes? _initialCustomersRoutes;
  final WorkOrdersRoutes? _initialWorkOrdersRoutes;
  final ProfileRoutes? _initialProfileRoutes;
  final ChecklistsRoutes? _initialChecklistsRoutes;
  final SettingsRoutes? _initialSettingsRoutes;

  HomeRoutes? _homeRoutes;
  CustomersRoutes? _customersRoutes;
  WorkOrdersRoutes? _workOrdersRoutes;
  ProfileRoutes? _profileRoutes;
  ChecklistsRoutes? _checklistsRoutes;
  SettingsRoutes? _settingsRoutes;

  void _initSubRoutes() {
    _homeRoutes = _initialHomeRoutes;
    _customersRoutes = _initialCustomersRoutes;
    _workOrdersRoutes = _initialWorkOrdersRoutes;
    _profileRoutes = _initialProfileRoutes;
    _checklistsRoutes = _initialChecklistsRoutes;
    _settingsRoutes = _initialSettingsRoutes;

    final db = services.database;
    if (db != null) {
      _homeRoutes ??= HomeRoutes.fromDatabase(db);
      _customersRoutes ??= CustomersRoutes.fromDatabase(db);
      _workOrdersRoutes ??= WorkOrdersRoutes.fromDatabase(
        database: db,
        locationService: services.locationService,
      );
      _profileRoutes ??= ProfileRoutes.standard();
      _checklistsRoutes ??= ChecklistsRoutes.fromDatabase(db);
      _settingsRoutes ??= SettingsRoutes.fromDatabase(db);
    }
  }

  /// Método gerador de rotas para plug-in em [MaterialApp.onGenerateRoute].
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      AppRoutes.initial => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AppGate(),
        ),
      AppRoutes.onboarding => _authRoutes.onboarding(
          onCompleted: () => _pushNamedReplacement(AppRoutes.home),
        ),
      AppRoutes.lock => _authRoutes.lock(
          onUnlocked: () => _pushNamedReplacement(AppRoutes.home),
          onForgotPin: () => _pushNamed(AppRoutes.recovery),
        ),
      AppRoutes.recovery => _authRoutes.recovery(
          onRecovered: () => _popAndPushNamedReplacement(AppRoutes.home),
        ),
      AppRoutes.home => _homeRoutes?.home(
          onProfile: () => _pushNamed(AppRoutes.profile),
          onCustomers: () => _pushNamed(AppRoutes.customers),
          onWorkOrders: () => _pushNamed(AppRoutes.workOrders),
          onNewWorkOrder: () => _pushNamed(AppRoutes.newWorkOrder),
          onChecklists: () => _pushNamed(AppRoutes.checklists),
          onSettings: () => _pushNamed(AppRoutes.settings),
          onSchedule: () => _pushNamed(AppRoutes.schedule),
        ),
      AppRoutes.profile => _profileRoutes?.edit(),
      AppRoutes.customers => _customersRoutes?.list(),
      AppRoutes.workOrders => _workOrdersRoutes?.list(),
      AppRoutes.schedule => _workOrdersRoutes?.list(),
      AppRoutes.newWorkOrder => _workOrdersRoutes?.form(),
      AppRoutes.checklists => _checklistsRoutes?.list(),
      AppRoutes.settings => _settingsRoutes?.edit(),
      _ => null,
    };
  }

  void _pushNamed(String routeName) {
    final nav = navigatorKey?.currentState;
    nav?.pushNamed(routeName);
  }

  void _pushNamedReplacement(String routeName) {
    final nav = navigatorKey?.currentState;
    nav?.pushReplacementNamed(routeName);
  }

  void _popAndPushNamedReplacement(String routeName) {
    final nav = navigatorKey?.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    }
    nav?.pushReplacementNamed(routeName);
  }
}
