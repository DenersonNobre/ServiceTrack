// Contêiner de dependências do app (composition root).
//
// SRP: agregar portas/adaptadores e políticas de configuração para injeção
// explícita no shell. Não cria regra de negócio nem conhece controllers de UI.

import '../modules/auth/domain/ports/.index.dart';
import '../modules/checklists/domain/ports/checklist_answer_repository_port.dart';
import '../modules/checklists/domain/ports/checklist_template_repository_port.dart';
import '../modules/customers/domain/ports/.index.dart';
import '../modules/profile/domain/ports/.index.dart';
import '../modules/settings/domain/.index.dart';
import '../modules/work_orders/domain/ports/.index.dart';

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
    this.requireChecklistTemplate = true,
    this.requireReceiverDocument = false,
  });

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
  final bool requireChecklistTemplate;
  final bool requireReceiverDocument;
}
