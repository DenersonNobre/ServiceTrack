import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'app/theme/app_colors.dart';
import 'modules/auth/data/biometric/local_auth_biometric_adapter.dart';
import 'modules/auth/data/credential_store/flutter_secure_storage_backend.dart';
import 'modules/auth/data/credential_store/secure_credential_store.dart';
import 'modules/auth/domain/ports/auth_credential_repository_port.dart';
import 'modules/auth/domain/ports/biometric_auth_port.dart';
import 'modules/auth/features/app_entry/resolve_initial_route_use_case.dart';
import 'modules/auth/features/biometric_unlock/biometric_unlock_use_case.dart';
import 'modules/auth/ui/lock/lock_controller.dart';
import 'modules/auth/ui/lock/lock_page.dart';
import 'modules/auth/ui/onboarding/onboarding_controller.dart';
import 'modules/auth/ui/onboarding/onboarding_page.dart';

void main() {
  runApp(const ServiceTrackApp());
}

/// Aplicativo raiz do ServiceTrack (standalone).
class ServiceTrackApp extends StatelessWidget {
  /// Cria o app; dependências podem ser injetadas em testes.
  const ServiceTrackApp({
    super.key,
    this.credentialRepository,
    this.biometricAuth,
  });

  /// Repositório de credenciais (injeção para testes).
  final IAuthCredentialRepositoryPort? credentialRepository;

  /// Porta biométrica (injeção para testes).
  final IBiometricAuthPort? biometricAuth;

  @override
  Widget build(BuildContext context) {
    final repo = credentialRepository ??
        SecureCredentialStore(backend: const FlutterSecureStorageBackend());
    final bio = biometricAuth ?? LocalAuthBiometricAdapter();
    return MaterialApp(
      title: 'ServiceTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryAction),
        scaffoldBackgroundColor: AppColors.surface,
        useMaterial3: true,
      ),
      home: _AppEntry(repo: repo, bio: bio),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry({required this.repo, required this.bio});

  final IAuthCredentialRepositoryPort repo;
  final IBiometricAuthPort bio;

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

  void _goHome() {
    if (!mounted) return;
    _isLockVisible = false;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const _HomePlaceholder()),
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
                  ),
                  dispose: (c) => c.dispose(),
                ),
              ],
              child: const LockPage(),
            ),
          AppEntryRoute.home => const _HomePlaceholder(),
        };
      },
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Home - ServiceTrack')),
    );
  }
}
