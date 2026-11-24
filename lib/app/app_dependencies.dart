// Contêiner de dependências do app (composition root).
//
// SRP: agregar portas/adaptadores e políticas de configuração para injeção
// explícita no shell. Não cria regra de negócio nem conhece controllers de UI.

import 'package:kortex_lib/sqlite/sqlite.dart';
import 'package:path_provider/path_provider.dart';

import '../modules/auth/data/biometric/.index.dart';
import '../modules/auth/data/credential_store/.index.dart';
import '../modules/auth/domain/ports/.index.dart';
import '../modules/checklists/data/.index.dart';
import '../modules/checklists/domain/ports/checklist_answer_repository_port.dart';
import '../modules/checklists/domain/ports/checklist_template_repository_port.dart';
import '../modules/customers/data/.index.dart';
import '../modules/customers/domain/ports/.index.dart';
import '../modules/profile/data/.index.dart';
import '../modules/profile/domain/ports/.index.dart';
import '../modules/settings/data/.index.dart';
import '../modules/settings/domain/.index.dart';
import '../modules/work_orders/data/.index.dart';
import '../modules/work_orders/domain/ports/.index.dart';
import 'adapters/checklist_proof_adapter.dart';

/// Dependências compartilhadas do aplicativo standalone.
final class AppDependencies {
  const AppDependencies({
    required this.credentialRepository,
    required this.biometricAuth,
    required this.profileRepository,
    required this.customerRepository,
    required this.locationRepository,
    required this.workOrderRepository,
    required this.locationService,
    required this.checklistProofPort,
    required this.checklistTemplateRepository,
    required this.checklistAnswerRepository,
    required this.settingsRepository,
  });

  /// Factory para criar dependências a partir do [SqliteProvider] (produção ou testes)
  /// ou instanciando fallbacks em memória para testes quando o banco for nulo.
  factory AppDependencies.fromDatabase({
    SqliteProvider? database,
    IAuthCredentialRepositoryPort? credentialRepository,
    IBiometricAuthPort? biometricAuth,
    ITechnicianProfileRepositoryPort? profileRepository,
    ICustomerRepositoryPort? customerRepository,
    IServiceLocationRepositoryPort? serviceLocationRepository,
    IWorkOrderRepositoryPort? workOrderRepository,
    ILocationServicePort? locationService,
    IChecklistTemplateRepositoryPort? checklistTemplateRepository,
    IChecklistAnswerRepositoryPort? checklistAnswerRepository,
    IChecklistProofPort? checklistProofPort,
    ISettingsRepositoryPort? settingsRepository,
  }) {
    final credRepo =
        credentialRepository ??
        SecureCredentialStore(backend: const FlutterSecureStorageBackend());
    final bio = biometricAuth ?? LocalAuthBiometricAdapter();
    final profileRepo =
        profileRepository ??
        (database != null
            ? FileTechnicianProfileRepository(
                baseDir: getApplicationSupportDirectory,
              )
            : MemoryTechnicianProfileRepository());
    final customerRepo =
        customerRepository ??
        (database != null
            ? CustomerSqliteRepository(provider: database)
            : MemoryCustomerRepository());
    final locationRepo =
        serviceLocationRepository ??
        (database != null
            ? ServiceLocationSqliteRepository(provider: database)
            : MemoryServiceLocationRepository());
    final workOrderRepo =
        workOrderRepository ??
        (database != null
            ? WorkOrderSqliteRepository(provider: database)
            : MemoryWorkOrderRepository());
    final location = locationService ?? GeolocatorLocationService();
    final templateRepo =
        checklistTemplateRepository ??
        (database != null
            ? ChecklistTemplateSqliteRepository(provider: database)
            : MemoryChecklistTemplateRepository());
    final answerRepo =
        checklistAnswerRepository ??
        (database != null
            ? ChecklistAnswerSqliteRepository(provider: database)
            : MemoryChecklistAnswerRepository());
    final proofPort =
        checklistProofPort ??
        ChecklistProofAdapter(
          templateRepository: templateRepo,
          answerRepository: answerRepo,
        );
    final settingsRepo =
        settingsRepository ??
        (database != null
            ? SettingsSqliteRepository(provider: database)
            : MemorySettingsRepository());

    return AppDependencies(
      credentialRepository: credRepo,
      biometricAuth: bio,
      profileRepository: profileRepo,
      customerRepository: customerRepo,
      locationRepository: locationRepo,
      workOrderRepository: workOrderRepo,
      locationService: location,
      checklistProofPort: proofPort,
      checklistTemplateRepository: templateRepo,
      checklistAnswerRepository: answerRepo,
      settingsRepository: settingsRepo,
    );
  }

  final IAuthCredentialRepositoryPort credentialRepository;
  final IBiometricAuthPort biometricAuth;
  final ITechnicianProfileRepositoryPort profileRepository;
  final ICustomerRepositoryPort customerRepository;
  final IServiceLocationRepositoryPort locationRepository;
  final IWorkOrderRepositoryPort workOrderRepository;
  final ILocationServicePort locationService;
  final IChecklistProofPort checklistProofPort;
  final IChecklistTemplateRepositoryPort checklistTemplateRepository;
  final IChecklistAnswerRepositoryPort checklistAnswerRepository;
  final ISettingsRepositoryPort settingsRepository;
}
