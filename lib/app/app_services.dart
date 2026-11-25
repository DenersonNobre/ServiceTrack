// Contêiner de serviços transversais e infraestrutura (composition root de serviços).
//
// Agrega exclusivamente serviços de infraestrutura e hardware:
// - Banco de dados (SqliteProvider)
// - Armazenamento de credenciais (IAuthCredentialRepositoryPort)
// - Autenticação biométrica (IBiometricAuthPort)
// - Serviço de geolocalização (ILocationServicePort)
//
// Zero imports de repositórios de módulos!

import 'package:kortex_lib/sqlite/sqlite.dart';

import '../core/security/aes_gcm_document_at_rest_cipher.dart';
import '../core/security/document_at_rest_cipher_port.dart';
import '../modules/auth/data/biometric/.index.dart';
import '../modules/auth/data/credential_store/.index.dart';
import '../modules/auth/domain/ports/.index.dart';
import '../modules/work_orders/data/geolocator_location_service.dart';
import '../modules/work_orders/domain/ports/location_service_port.dart';

final class AppServices {
  const AppServices({
    this.database,
    required this.credentialStore,
    required this.biometricAuth,
    required this.locationService,
    this.documentCipher,
  });

  /// Instância do banco SQLite local (opcional em testes com fakes puros).
  final SqliteProvider? database;
  final IAuthCredentialRepositoryPort credentialStore;
  final IBiometricAuthPort biometricAuth;
  final ILocationServicePort locationService;
  /// Cifrador de PII em repouso (D-01/C-01). Null = fail-closed.
  final IDocumentAtRestCipher? documentCipher;

  factory AppServices.fromDatabase({
    SqliteProvider? database,
    IAuthCredentialRepositoryPort? credentialStore,
    IBiometricAuthPort? biometricAuth,
    ILocationServicePort? locationService,
    IDocumentAtRestCipher? documentCipher,
  }) {
    final credStore =
        credentialStore ??
        SecureCredentialStore(backend: const FlutterSecureStorageBackend());
    final bio = biometricAuth ?? LocalAuthBiometricAdapter();
    final location = locationService ?? GeolocatorLocationService();
    final cipher = documentCipher ?? AesGcmDocumentAtRestCipher();

    return AppServices(
      database: database,
      credentialStore: credStore,
      biometricAuth: bio,
      locationService: location,
      documentCipher: cipher,
    );
  }
}
