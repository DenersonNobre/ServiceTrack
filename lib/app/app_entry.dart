// Gate de entrada, observador de ciclo de vida e roteamento de módulos.

import 'package:dnolib/core/patterns/result.dart';
import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../modules/auth/features/app_entry/.index.dart';
import '../modules/auth/features/biometric_unlock/.index.dart';
import '../modules/auth/features/recovery/.index.dart';
import '../modules/auth/ui/lock/.index.dart';
import '../modules/auth/ui/onboarding/.index.dart';
import '../modules/auth/ui/recovery/.index.dart';
import '../modules/checklists/ui/execution/checklist_execution_controller.dart';
import '../modules/checklists/ui/execution/checklist_execution_page.dart';
import '../modules/customers/ui/customers_routes.dart';
import '../modules/profile/ui/profile/.index.dart';
import '../modules/work_orders/domain/value_objects/work_order_status.dart';
import '../modules/work_orders/ui/form/.index.dart';
import '../modules/work_orders/ui/list/.index.dart';
import 'app_dependencies.dart';
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
  late final CustomersRoutes _customersRoutes;
  DateTime? _backgroundedAt;
  bool _isLockVisible = false;
  static const _backgroundLockTtl = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _customersRoutes = CustomersRoutes(
      customerRepository: widget.deps.customerRepository,
      locationRepository: widget.deps.locationRepository,
    );
    _routeFuture = ResolveInitialRouteUseCase(
      repo: widget.deps.credentialRepository,
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
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<ProfileController>(
              create: (_) =>
                  ProfileController(repository: widget.deps.profileRepository),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const ProfilePage(),
        ),
      ),
    );
  }

  void _goCustomers() {
    if (!mounted) return;
    Navigator.of(context).push(_customersRoutes.list());
  }

  void _goWorkOrderForm({VoidCallback? onSaved}) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<WorkOrderFormController>(
              create: (_) => WorkOrderFormController(
                repository: widget.deps.workOrderRepository,
                customerRepository: widget.deps.customerRepository,
                checklistTemplateRepository:
                    widget.deps.checklistTemplateRepository,
              ),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: WorkOrderFormPage(
            onSaved: () {
              Navigator.of(context).pop();
              onSaved?.call();
            },
          ),
        ),
      ),
    );
  }

  void _goChecklistExecution({
    required String workOrderId,
    required String templateId,
  }) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<ChecklistExecutionController>(
              create: (_) => ChecklistExecutionController(
                templateRepository: widget.deps.checklistTemplateRepository,
                answerRepository: widget.deps.checklistAnswerRepository,
                workOrderId: workOrderId,
                templateId: templateId,
                isWorkOrderMutable: () async {
                  final r = await widget.deps.workOrderRepository.findAll();
                  switch (r) {
                    case Success(:final value):
                      final wo = value
                          .where((e) => e.id == workOrderId)
                          .firstOrNull;
                      return wo != null &&
                          wo.status != WorkOrderStatus.completed &&
                          wo.status != WorkOrderStatus.cancelled;
                    case Failure():
                      return false;
                  }
                },
              ),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const ChecklistExecutionPage(),
        ),
      ),
    );
  }

  void _goWorkOrders() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<WorkOrderListController>(
              create: (_) => WorkOrderListController(
                repository: widget.deps.workOrderRepository,
                locationService: widget.deps.locationService,
                checklistProofPort: widget.deps.checklistProofPort,
                requireChecklistTemplate: widget.deps.requireChecklistTemplate,
                requireReceiverDocument: widget.deps.requireReceiverDocument,
              ),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: Builder(
            builder: (ctx) {
              final list = ctx.readKortex<WorkOrderListController>();
              return WorkOrderListPage(
                onAdd: () => _goWorkOrderForm(onSaved: list.load),
                onChecklist: (woId, tplId) =>
                    _goChecklistExecution(workOrderId: woId, templateId: tplId),
              );
            },
          ),
        ),
      ),
    );
  }

  void _goHome() {
    if (!mounted) return;
    _isLockVisible = false;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomePage(
          onProfile: _goProfile,
          onCustomers: _goCustomers,
          onWorkOrders: _goWorkOrders,
        ),
      ),
    );
  }

  void _goRecovery() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<PinRecoveryController>(
              create: (_) => PinRecoveryController(
                useCase: PinRecoveryUseCase(
                  repository: widget.deps.credentialRepository,
                  biometricAuth: widget.deps.biometricAuth,
                ),
                repository: widget.deps.credentialRepository,
                onRecovered: () {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  _goHome();
                },
              ),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const PinRecoveryPage(),
        ),
      ),
    );
  }

  void _goLock() {
    if (!mounted) return;
    _isLockVisible = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<LockController>(
              create: (_) => LockController(
                biometricUnlock: BiometricUnlockUseCase(
                  biometricAuth: widget.deps.biometricAuth,
                ),
                repository: widget.deps.credentialRepository,
                onUnlocked: _goHome,
                onForgotPin: _goRecovery,
              ),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const LockPage(),
        ),
      ),
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
          AppEntryRoute.onboarding => KortexScope(
            providers: [
              KortexProvider<OnboardingController>(
                create: (_) => OnboardingController(
                  repository: widget.deps.credentialRepository,
                  onCompleted: () {
                    // ignore: discarded_futures
                    widget.deps.credentialRepository.markUnlocked();
                    _goHome();
                  },
                ),
                dispose: (c) => c.dispose(),
              ),
            ],
            child: const OnboardingPage(),
          ),
          AppEntryRoute.lock => KortexScope(
            providers: [
              KortexProvider<LockController>(
                create: (_) => LockController(
                  biometricUnlock: BiometricUnlockUseCase(
                    biometricAuth: widget.deps.biometricAuth,
                  ),
                  repository: widget.deps.credentialRepository,
                  onUnlocked: _goHome,
                  onForgotPin: _goRecovery,
                ),
                dispose: (c) => c.dispose(),
              ),
            ],
            child: const LockPage(),
          ),
          AppEntryRoute.home => HomePage(
            onProfile: _goProfile,
            onCustomers: _goCustomers,
            onWorkOrders: _goWorkOrders,
          ),
        };
      },
    );
  }
}
