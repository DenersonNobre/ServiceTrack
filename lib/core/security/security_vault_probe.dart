// Serviço de diagnóstico e verificação de integridade do cofre do SO (UC-08.01 / D-01 / C-01).
//
// SRP: verificar se o cofre do SO (Android Keystore / iOS Keychain) está funcional
// realizando ciclo atômico de escrita, leitura e limpeza de chave de probe efêmera.
// NÃO cifra PII diretamente, NÃO gerencia tabelas SQLite.

import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kortex_lib/kortex_lib.dart';

import 'document_at_rest_failure_codes.dart';

/// Contrato da porta de verificação de disponibilidade do cofre do SO.
abstract interface class ISecurityVaultProbe {
  /// Verifica se o cofre de chaves do SO está responsivo e operacional.
  ///
  /// Retorna [Success] com `true` em caso de êxito total na escrita, leitura e limpeza.
  /// Retorna [Failure] com código tipado em caso de erro de I/O ou hardware.
  Future<IResult<bool, ValidationError>> checkVaultAvailability();
}

/// Implementação padrão do probe de integridade do cofre seguro.
final class SecurityVaultProbe implements ISecurityVaultProbe {
  SecurityVaultProbe({
    FlutterSecureStorage? secureStorage,
    this.probeKey = _defaultProbeKey,
  }) : _secureStorage =
           secureStorage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           );

  static const _defaultProbeKey = 'st.vault.probe.check.ephemeral';

  final FlutterSecureStorage _secureStorage;
  final String probeKey;

  @override
  Future<IResult<bool, ValidationError>> checkVaultAvailability() async {
    final token = 'probe_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1000000)}';
    try {
      // 1. Escrita atômica do token de probe
      await _secureStorage.write(key: probeKey, value: token);

      // 2. Leitura e validação de consistência
      final readBack = await _secureStorage.read(key: probeKey);
      if (readBack != token) {
        return const Failure(
          ValidationError(
            code: DocumentAtRestFailureCodes.vaultUnavailable,
            message: 'O cofre do SO retornou dado divergente do token emitido.',
          ),
        );
      }

      // 3. Limpeza do token efêmero
      await _secureStorage.delete(key: probeKey);

      return const Success(true);
    } on Object catch (e) {
      return Failure(
        ValidationError(
          code: DocumentAtRestFailureCodes.vaultUnavailable,
          message: 'Falha de comunicação/hardware com o cofre do SO: $e',
        ),
      );
    }
  }
}
