// Widget raiz do aplicativo ServiceTrack (composição de tema e portas).

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import '../modules/auth/domain/ports/.index.dart';
import '../modules/checklists/.index.dart';
import '../modules/customers/domain/ports/.index.dart';
import '../modules/profile/domain/ports/.index.dart';
import '../modules/settings/domain/.index.dart';
import '../modules/work_orders/domain/ports/.index.dart';
import 'app_dependencies.dart';
import 'app_entry.dart';
import 'theme/app_theme.dart';

/// Aplicativo raiz do ServiceTrack (standalone).
class ServiceTrackApp extends StatelessWidget {
  /// Cria o app; dependências podem ser injetadas em testes ou derivadas do [database].
  const ServiceTrackApp({
    super.key,
    this.database,
    this.credentialRepository,
    this.biometricAuth,
    this.profileRepository,
    this.customerRepository,
    this.serviceLocationRepository,
    this.workOrderRepository,
    this.locationService,
    this.checklistTemplateRepository,
    this.checklistAnswerRepository,
    this.checklistProofPort,
    this.settingsRepository,
  });

  /// Instância do banco SQLite local (opcional para testes unitários).
  final SqliteProvider? database;

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

  /// Repositório de templates de checklist (injeção para testes).
  final IChecklistTemplateRepositoryPort? checklistTemplateRepository;

  /// Repositório de respostas de checklist (injeção para testes).
  final IChecklistAnswerRepositoryPort? checklistAnswerRepository;

  /// Porta de prova de checklist para conclusão de OS (injeção para testes).
  final IChecklistProofPort? checklistProofPort;

  /// Repositório de configurações locais (injeção para testes).
  final ISettingsRepositoryPort? settingsRepository;

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.fromDatabase(
      database: database,
      credentialRepository: credentialRepository,
      biometricAuth: biometricAuth,
      profileRepository: profileRepository,
      customerRepository: customerRepository,
      serviceLocationRepository: serviceLocationRepository,
      workOrderRepository: workOrderRepository,
      locationService: locationService,
      checklistTemplateRepository: checklistTemplateRepository,
      checklistAnswerRepository: checklistAnswerRepository,
      checklistProofPort: checklistProofPort,
      settingsRepository: settingsRepository,
    );
    final db = database;
    return KortexMaterialApp(
      providers: [
        KortexProvider<AppDependencies>(
          create: (_) => dependencies,
        ),
        if (db != null) KortexProvider<SqliteProvider>.value(value: db),
      ],
      app: MaterialApp(
        title: 'ServiceTrack',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        home: AppEntry(deps: dependencies),
      ),
    );
  }
}
