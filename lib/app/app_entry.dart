// Gate de entrada, observador de ciclo de vida e roteamento de módulos.

import 'package:flutter/material.dart';

import '../modules/auth/features/app_entry/.index.dart';
import '../modules/auth/ui/auth_routes.dart';
import '../modules/checklists/ui/checklists_routes.dart';
import '../modules/customers/ui/customers_routes.dart';
import '../modules/profile/ui/profile_routes.dart';
import '../modules/settings/ui/.index.dart';
import '../modules/work_orders/ui/work_orders_routes.dart';
import 'app_dependencies.dart';
import 'home_dashboard_controller.dart';
import 'home_page.dart';

/// Porta de entrada do aplicativo após o [MaterialApp].
class AppEntry extends StatefulWidget {
  const AppEntry({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with WidgetsBindingObserver {
  late final Future<AppEntryRoute> _routeFuture;
  late final AuthRoutes _authRoutes;
  late final ChecklistsRoutes _checklistsRoutes;
  late final CustomersRoutes _customersRoutes;
  late final ProfileRoutes _profileRoutes;
  late final SettingsRoutes _settingsRoutes;
  late final WorkOrdersRoutes _workOrdersRoutes;
  late final HomeDashboardController _homeController;
  DateTime? _backgroundedAt;
  bool _isLockVisible = false;
  static const _backgroundLockTtl = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authRoutes = AuthRoutes(
      credentialRepository: widget.deps.credentialRepository,
      biometricAuth: widget.deps.biometricAuth,
    );
    _checklistsRoutes = ChecklistsRoutes(
      templateRepository: widget.deps.checklistTemplateRepository,
    );
    _customersRoutes = CustomersRoutes(
      customerRepository: widget.deps.customerRepository,
      locationRepository: widget.deps.locationRepository,
    );
    _profileRoutes = ProfileRoutes(
      profileRepository: widget.deps.profileRepository,
    );
    _settingsRoutes = SettingsRoutes(
      settingsRepository: widget.deps.settingsRepository,
    );
    _workOrdersRoutes = WorkOrdersRoutes(
      workOrderRepository: widget.deps.workOrderRepository,
      customerRepository: widget.deps.customerRepository,
      locationService: widget.deps.locationService,
      checklistProofPort: widget.deps.checklistProofPort,
      checklistTemplateRepository: widget.deps.checklistTemplateRepository,
      checklistAnswerRepository: widget.deps.checklistAnswerRepository,
      settingsRepository: widget.deps.settingsRepository,
    );
    _homeController = HomeDashboardController(
      repository: widget.deps.workOrderRepository,
    );
    _routeFuture = ResolveInitialRouteUseCase(
      repo: widget.deps.credentialRepository,
    ).execute();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final at = _backgroundedAt;
      _backgroundedAt = null;
      if (at == null || _isLockVisible) return;
      if (DateTime.now().difference(at) > _backgroundLockTtl) {
        _goLock();
      }
    }
  }

  void _goProfile() {
    if (!mounted) return;
    Navigator.of(context).push(_profileRoutes.edit());
  }

  void _goCustomers() {
    if (!mounted) return;
    Navigator.of(context).push(_customersRoutes.list());
  }

  void _goSettings() {
    if (!mounted) return;
    Navigator.of(context).push(_settingsRoutes.edit());
  }

  void _goChecklists() {
    if (!mounted) return;
    Navigator.of(context).push(_checklistsRoutes.list());
  }

  void _goWorkOrders() {
    if (!mounted) return;
    Navigator.of(context).push(_workOrdersRoutes.list());
  }

  void _goNewWorkOrder() {
    if (!mounted) return;
    Navigator.of(context).push(
      _workOrdersRoutes.form(
        onSaved: () {
          // ignore: discarded_futures
          _homeController.load();
        },
      ),
    );
  }

  void _goHome() {
    if (!mounted) return;
    _isLockVisible = false;
    // ignore: discarded_futures
    _homeController.load();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomePage(
          controller: _homeController,
          onProfile: _goProfile,
          onCustomers: _goCustomers,
          onWorkOrders: _goWorkOrders,
          onNewWorkOrder: _goNewWorkOrder,
          onChecklists: _goChecklists,
          onSettings: _goSettings,
        ),
      ),
    );
  }

  void _goRecovery() {
    if (!mounted) return;
    Navigator.of(context).push(
      _authRoutes.recovery(
        onRecovered: () {
          if (!mounted) return;
          Navigator.of(context).pop();
          _goHome();
        },
      ),
    );
  }

  void _goLock() {
    if (!mounted) return;
    _isLockVisible = true;
    Navigator.of(context).pushReplacement(
      _authRoutes.lock(onUnlocked: _goHome, onForgotPin: _goRecovery),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppEntryRoute>(
      future: _routeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final route = snapshot.data!;
        if (route == AppEntryRoute.lock) _isLockVisible = true;
        if (route == AppEntryRoute.home || route == AppEntryRoute.onboarding) {
          _isLockVisible = false;
        }
        return switch (route) {
          AppEntryRoute.onboarding => _authRoutes.onboardingWidget(
            onCompleted: _goHome,
          ),
          AppEntryRoute.lock => _authRoutes.lockWidget(
            onUnlocked: _goHome,
            onForgotPin: _goRecovery,
          ),
          AppEntryRoute.home => HomePage(
            controller: _homeController,
            onProfile: _goProfile,
            onCustomers: _goCustomers,
            onWorkOrders: _goWorkOrders,
            onNewWorkOrder: _goNewWorkOrder,
            onChecklists: _goChecklists,
            onSettings: _goSettings,
          ),
        };
      },
    );
  }
}
