// Widget raiz do aplicativo ServiceTrack (composição de tema e portas).

import 'package:flutter/material.dart';

import '../modules/auth/data/biometric/.index.dart';
import '../modules/auth/data/credential_store/.index.dart';
import '../modules/auth/domain/ports/.index.dart';
import '../modules/customers/data/.index.dart';
import '../modules/customers/domain/ports/.index.dart';
import '../modules/profile/data/.index.dart';
import '../modules/profile/domain/ports/.index.dart';
import '../modules/work_orders/data/.index.dart';
import '../modules/work_orders/domain/ports/.index.dart';
import 'app_entry.dart';
import 'theme/app_colors.dart';

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
    final locationRepo =
        serviceLocationRepository ?? MemoryServiceLocationRepository();
    final workOrderRepo = workOrderRepository ?? MemoryWorkOrderRepository();
    final location = locationService ?? GeolocatorLocationService();
    return MaterialApp(
      title: 'ServiceTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryAction),
        scaffoldBackgroundColor: AppColors.surface,
        useMaterial3: true,
      ),
      home: AppEntry(
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
