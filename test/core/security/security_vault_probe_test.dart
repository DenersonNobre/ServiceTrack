import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/core/security/document_at_rest_failure_codes.dart';
import 'package:service_track/core/security/security_vault_probe.dart';

final class _OperationalSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

final class _FailingWriteSecureStorage extends FlutterSecureStorage {
  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('Keystore write failed: platform unavailable');
  }
}

final class _CorruptedReadSecureStorage extends FlutterSecureStorage {
  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {}

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => 'unexpected-value';

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {}
}

final class _FailingDeleteSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _data[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('Keychain delete failed: hardware timeout');
  }
}

void main() {
  group('SecurityVaultProbe (UC-08.01 / D-01 / C-01)', () {
    test('retorna Success(true) quando o cofre suporta escrita, leitura e deleção atômica', () async {
      final storage = _OperationalSecureStorage();
      final probe = SecurityVaultProbe(secureStorage: storage);

      final result = await probe.checkVaultAvailability();

      expect(result.isSuccess, isTrue);
      expect(result.getOrNull(), isTrue);
    });

    test('retorna Failure(ERR_VAULT_UNAVAILABLE) quando a escrita no cofre falha com exceção', () async {
      final storage = _FailingWriteSecureStorage();
      final probe = SecurityVaultProbe(secureStorage: storage);

      final result = await probe.checkVaultAvailability();

      expect(result.isFailure, isTrue);
      final error = result.getOrNullFailure();
      expect(error, isNotNull);
      expect(error!.code, equals(DocumentAtRestFailureCodes.vaultUnavailable));
    });

    test('retorna Failure(ERR_VAULT_UNAVAILABLE) quando a leitura do token de probe não coincide', () async {
      final storage = _CorruptedReadSecureStorage();
      final probe = SecurityVaultProbe(secureStorage: storage);

      final result = await probe.checkVaultAvailability();

      expect(result.isFailure, isTrue);
      final error = result.getOrNullFailure();
      expect(error, isNotNull);
      expect(error!.code, equals(DocumentAtRestFailureCodes.vaultUnavailable));
    });

    test('retorna Failure(ERR_VAULT_UNAVAILABLE) quando a deleção no cofre falha', () async {
      final storage = _FailingDeleteSecureStorage();
      final probe = SecurityVaultProbe(secureStorage: storage);

      final result = await probe.checkVaultAvailability();

      expect(result.isFailure, isTrue);
      final error = result.getOrNullFailure();
      expect(error, isNotNull);
      expect(error!.code, equals(DocumentAtRestFailureCodes.vaultUnavailable));
    });
  });
}
