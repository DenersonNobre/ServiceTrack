import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kortex/kortex.dart';
import 'package:path_provider/path_provider.dart';

import 'app/theme/app_colors.dart';
import 'modules/auth/data/biometric/.index.dart';
import 'modules/auth/data/credential_store/.index.dart';
import 'modules/auth/domain/ports/.index.dart';
import 'modules/auth/features/app_entry/.index.dart';
import 'modules/auth/features/biometric_unlock/.index.dart';
import 'modules/auth/features/recovery/.index.dart';
import 'modules/auth/ui/lock/.index.dart';
import 'modules/auth/ui/onboarding/.index.dart';
import 'modules/auth/ui/recovery/.index.dart';
import 'modules/profile/data/.index.dart';
import 'modules/profile/domain/ports/.index.dart';
import 'modules/profile/ui/profile/.index.dart';
import 'modules/work_orders/data/.index.dart';
import 'modules/work_orders/domain/ports/.index.dart';
import 'modules/work_orders/ui/form/.index.dart';
import 'modules/work_orders/ui/list/.index.dart';
import 'app/database/app_database.dart';
import 'modules/customers/data/.index.dart';
import 'modules/customers/domain/ports/.index.dart';
import 'modules/customers/domain/value_objects/.index.dart';
import 'modules/customers/ui/detail/.index.dart';
import 'modules/customers/ui/form/.index.dart';
import 'modules/customers/ui/list/.index.dart';
import 'modules/customers/ui/locations/.index.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
  if (view != null) {
    final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
    if (shortestSide < 600) {
      // ignore: discarded_futures
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }
  final db = createAppDatabase();
  runApp(
    ServiceTrackApp(
      profileRepository: FileTechnicianProfileRepository(
        baseDir: getApplicationSupportDirectory,
      ),
      customerRepository: CustomerSqliteRepository(provider: db),
      serviceLocationRepository: ServiceLocationSqliteRepository(provider: db),
      workOrderRepository: WorkOrderSqliteRepository(provider: db),
    ),
  );
}

/// Aplicativo raiz do ServiceTrack (standalone).
class ServiceTrackApp extends StatelessWidget {
  /// Cria o app; dependências podem ser injetadas em testes.
  const ServiceTrackApp({
    super.key,
    this.credentialRepository,
    this.biometricAuth,
    this.profileRepository,
    this.customerRepository,
    this.serviceLocationRepository,
    this.workOrderRepository,
    this.locationService,
  });

  /// Repositório de credenciais (injeção para testes).
  final IAuthCredentialRepositoryPort? credentialRepository;

  /// Porta biométrica (injeção para testes).
  final IBiometricAuthPort? biometricAuth;

  /// Repositório de perfil comercial (injeção para testes).
  final ITechnicianProfileRepositoryPort? profileRepository;

  /// Repositório de clientes (injeção para testes).
  final ICustomerRepositoryPort? customerRepository;

  /// Repositório de locais de atendimento (injeção para testes).
  final IServiceLocationRepositoryPort? serviceLocationRepository;

  /// Repositório de Ordens de Serviço (injeção para testes).
  final IWorkOrderRepositoryPort? workOrderRepository;

  /// Porta de localização (injeção para testes).
  final ILocationServicePort? locationService;

  @override
  Widget build(BuildContext context) {
    final repo = credentialRepository ??
        SecureCredentialStore(backend: const FlutterSecureStorageBackend());
    final bio = biometricAuth ?? LocalAuthBiometricAdapter();
    final profileRepo =
        profileRepository ?? MemoryTechnicianProfileRepository();
    final customerRepo = customerRepository ?? MemoryCustomerRepository();
    final locationRepo = serviceLocationRepository ?? MemoryServiceLocationRepository();
    final workOrderRepo = workOrderRepository ?? MemoryWorkOrderRepository();
    final location = locationService ?? GeolocatorLocationService();
    return MaterialApp(
      title: 'ServiceTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryAction),
        scaffoldBackgroundColor: AppColors.surface,
        useMaterial3: true,
      ),
      home: _AppEntry(
        repo: repo,
        bio: bio,
        profileRepo: profileRepo,
        customerRepo: customerRepo,
        locationRepo: locationRepo,
        workOrderRepo: workOrderRepo,
        locationService: location,
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry({
    required this.repo,
    required this.bio,
    required this.profileRepo,
    required this.customerRepo,
    required this.locationRepo,
    required this.workOrderRepo,
    required this.locationService,
  });

  final IAuthCredentialRepositoryPort repo;
  final IBiometricAuthPort bio;
  final ITechnicianProfileRepositoryPort profileRepo;
  final ICustomerRepositoryPort customerRepo;
  final IServiceLocationRepositoryPort locationRepo;
  final IWorkOrderRepositoryPort workOrderRepo;
  final ILocationServicePort locationService;

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> with WidgetsBindingObserver {
  late final Future<AppEntryRoute> _routeFuture;
  DateTime? _backgroundedAt;
  bool _isLockVisible = false;
  static const _backgroundLockTtl = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _routeFuture = ResolveInitialRouteUseCase(repo: widget.repo).execute();
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
              create: (_) => ProfileController(repository: widget.profileRepo),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: const ProfilePage(),
        ),
      ),
    );
  }

  void _goCustomerForm({String? customerId, VoidCallback? onSaved}) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<CustomerFormController>(
              create: (_) => CustomerFormController(repository: widget.customerRepo, customerId: customerId),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: CustomerFormPage(onSaved: () { Navigator.of(context).pop(); onSaved?.call(); }),
        ),
      ),
    );
  }

  void _goLocationForm({
    required String customerId,
    String? locationId,
    ServiceLocation? initial,
    VoidCallback? onSaved,
  }) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<ServiceLocationFormController>(
              create: (_) => ServiceLocationFormController(
                repository: widget.locationRepo,
                customerId: customerId,
                locationId: locationId,
                initial: initial,
              ),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: ServiceLocationFormPage(onSaved: () {
            Navigator.of(context).pop();
            onSaved?.call();
          }),
        ),
      ),
    );
  }

  void _goLocations(Customer customer) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<ServiceLocationListController>(
              create: (_) => ServiceLocationListController(
                repository: widget.locationRepo,
                customerId: customer.id,
              ),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: Builder(
            builder: (ctx) {
              final list = ctx.readKortex<ServiceLocationListController>();
              return ServiceLocationListPage(
                customerName: customer.name.value,
                onAdd: () => _goLocationForm(customerId: customer.id, onSaved: list.load),
                onEdit: (l) => _goLocationForm(
                  customerId: customer.id,
                  locationId: l.id,
                  initial: l,
                  onSaved: list.load,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _goCustomerDetail(Customer customer) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<CustomerDetailController>(
              create: (_) => CustomerDetailController(repository: widget.customerRepo, customerId: customer.id),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: Builder(
            builder: (ctx) {
              final detail = ctx.readKortex<CustomerDetailController>();
              return CustomerDetailPage(
                onEdit: () => _goCustomerForm(customerId: customer.id, onSaved: detail.load),
                onLocations: () => _goLocations(customer),
              );
            },
          ),
        ),
      ),
    );
  }

  void _goCustomers() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<CustomerListController>(
              create: (_) => CustomerListController(repository: widget.customerRepo),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: Builder(
            builder: (ctx) {
              final list = ctx.readKortex<CustomerListController>();
              return CustomerListPage(
                onAdd: () => _goCustomerForm(onSaved: list.load),
                onEdit: (c) => _goCustomerForm(customerId: c.id, onSaved: list.load),
                onLocations: _goLocations,
                onDetail: _goCustomerDetail,
              );
            },
          ),
        ),
      ),
    );
  }

  void _goWorkOrderForm({VoidCallback? onSaved}) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KortexScope(
          providers: [
            KortexProvider<WorkOrderFormController>(
              create: (_) => WorkOrderFormController(repository: widget.workOrderRepo, customerRepository: widget.customerRepo),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: WorkOrderFormPage(onSaved: () { Navigator.of(context).pop(); onSaved?.call(); }),
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
                repository: widget.workOrderRepo,
                locationService: widget.locationService,
              ),
              dispose: (c) => c.dispose(),
            ),
          ],
          child: Builder(
            builder: (ctx) {
              final list = ctx.readKortex<WorkOrderListController>();
              return WorkOrderListPage(onAdd: () => _goWorkOrderForm(onSaved: list.load));
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
        builder: (_) => _HomePlaceholder(onProfile: _goProfile, onCustomers: _goCustomers, onWorkOrders: _goWorkOrders),
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
                  repository: widget.repo,
                  biometricAuth: widget.bio,
                ),
                repository: widget.repo,
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
                biometricUnlock:
                    BiometricUnlockUseCase(biometricAuth: widget.bio),
                repository: widget.repo,
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
                    repository: widget.repo,
                    onCompleted: () {
                      widget.repo.markUnlocked();
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
                    biometricUnlock:
                        BiometricUnlockUseCase(biometricAuth: widget.bio),
                    repository: widget.repo,
                    onUnlocked: _goHome,
                    onForgotPin: _goRecovery,
                  ),
                  dispose: (c) => c.dispose(),
                ),
              ],
              child: const LockPage(),
            ),
          AppEntryRoute.home => _HomePlaceholder(onProfile: _goProfile, onCustomers: _goCustomers, onWorkOrders: _goWorkOrders),
        };
      },
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder({required this.onProfile, required this.onCustomers, required this.onWorkOrders});

  final VoidCallback onProfile;
  final VoidCallback onCustomers;
  final VoidCallback onWorkOrders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ServiceTrack'),
        actions: [
          IconButton(
            key: const Key('home-work-orders'),
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Ordens de Serviço',
            onPressed: onWorkOrders,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          IconButton(
            key: const Key('home-customers'),
            icon: const Icon(Icons.people_outline),
            tooltip: 'Clientes',
            onPressed: onCustomers,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          IconButton(
            key: const Key('home-profile'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil comercial',
            onPressed: onProfile,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: const Center(child: Text('Home - ServiceTrack')),
    );
  }
}
