import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'app/theme/app_colors.dart';
import 'modules/auth/domain/ports/auth_credential_repository_port.dart';
import 'modules/auth/data/credential_store/flutter_secure_storage_backend.dart';
import 'modules/auth/data/credential_store/secure_credential_store.dart';
import 'modules/auth/ui/onboarding/onboarding_controller.dart';
import 'modules/auth/ui/onboarding/onboarding_page.dart';

void main() {
  runApp(const ServiceTrackApp());
}

/// Aplicativo raiz do ServiceTrack (standalone).
class ServiceTrackApp extends StatelessWidget {
  /// Cria o app; [credentialRepository] permite injeção em testes.
  const ServiceTrackApp({
    super.key,
    this.credentialRepository,
  });

  final IAuthCredentialRepositoryPort? credentialRepository;

  @override
  Widget build(BuildContext context) {
    final repository = credentialRepository ??
        SecureCredentialStore(backend: const FlutterSecureStorageBackend());
    return MaterialApp(
      title: 'ServiceTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryAction,
        ),
        scaffoldBackgroundColor: AppColors.surface,
        useMaterial3: true,
      ),
      home: KortexScope(
        providers: [
          KortexProvider<OnboardingController>(
            create: (_) => OnboardingController(repository: repository),
            dispose: (c) => c.dispose(),
          ),
        ],
        child: const OnboardingPage(),
      ),
    );
  }
}
