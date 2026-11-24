// Gate de entrada, observador de ciclo de vida e roteamento de módulos.

import 'package:flutter/material.dart';

import '../modules/auth/features/app_entry/.index.dart';
import '../modules/auth/ui/auth_routes.dart';
import '../modules/checklists/ui/checklists_routes.dart';
import '../modules/customers/ui/customers_routes.dart';
import '../modules/home/ui/home_routes.dart';
import '../modules/profile/ui/profile_routes.dart';
import '../modules/settings/ui/.index.dart';
import '../modules/work_orders/ui/work_orders_routes.dart';
import 'app_services.dart';

/// Porta de entrada do aplicativo após o [MaterialApp].
class AppEntry extends StatefulWidget {
  const AppEntry({super.key, required this.services});

  final AppServices services;

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> with WidgetsBindingObserver {
  late final Future<AppEntryRoute> _routeFuture;
  late final AuthRoutes _authRoutes;
  ChecklistsRoutes? _checklistsRoutes;
  CustomersRoutes? _customersRoutes;
  HomeRoutes? _homeRoutes;
  ProfileRoutes? _profileRoutes;
  SettingsRoutes? _settingsRoutes;
  WorkOrdersRoutes? _workOrdersRoutes;
  DateTime? _backgroundedAt;
  bool _isLockVisible = false;
  static const _backgroundLockTtl = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final db = widget.services.database;
    _authRoutes = AuthRoutes.fromServices(widget.services);
    if (db != null) {
      _checklistsRoutes = ChecklistsRoutes.fromDatabase(db);
      _customersRoutes = CustomersRoutes.fromDatabase(db);
      _homeRoutes = HomeRoutes.fromDatabase(db);
      _profileRoutes = ProfileRoutes.standard();
      _settingsRoutes = SettingsRoutes.fromDatabase(db);
      _workOrdersRoutes = WorkOrdersRoutes.fromDatabase(
        database: db,
        locationService: widget.services.locationService,
      );
    }
    _routeFuture = ResolveInitialRouteUseCase(
      repo: widget.services.credentialStore,
    ).execute();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    if (!mounted || _profileRoutes == null) return;
    Navigator.of(context).push(_profileRoutes!.edit());
  }

  void _goCustomers() {
    if (!mounted || _customersRoutes == null) return;
    Navigator.of(context).push(_customersRoutes!.list());
  }

  void _goWorkOrders() {
    if (!mounted || _workOrdersRoutes == null) return;
    Navigator.of(context).push(_workOrdersRoutes!.list());
  }

  void _goNewWorkOrder() {
    if (!mounted || _workOrdersRoutes == null) return;
    Navigator.of(context).push(_workOrdersRoutes!.form());
  }

  void _goChecklists() {
    if (!mounted || _checklistsRoutes == null) return;
    Navigator.of(context).push(_checklistsRoutes!.list());
  }

  void _goSettings() {
    if (!mounted || _settingsRoutes == null) return;
    Navigator.of(context).push(_settingsRoutes!.edit());
  }

  void _goHome() {
    if (!mounted || _homeRoutes == null) return;
    _isLockVisible = false;
    Navigator.of(context).pushReplacement(
      _homeRoutes!.home(
        onProfile: _goProfile,
        onCustomers: _goCustomers,
        onWorkOrders: _goWorkOrders,
        onNewWorkOrder: _goNewWorkOrder,
        onChecklists: _goChecklists,
        onSettings: _goSettings,
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
          AppEntryRoute.home => _homeRoutes != null
              ? _homeRoutes!.homeWidget(
                  onProfile: _goProfile,
                  onCustomers: _goCustomers,
                  onWorkOrders: _goWorkOrders,
                  onNewWorkOrder: _goNewWorkOrder,
                  onChecklists: _goChecklists,
                  onSettings: _goSettings,
                )
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
        };
      },
    );
  }
}
