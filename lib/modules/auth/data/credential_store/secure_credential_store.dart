// Repositório das credenciais no cofre local (UC-01.01, TASK-02).
//
// SRP: cadastra, verifica (com rate-limit do PIN) e limpa credenciais.
// NÃO deriva fora de credential_kdf, NÃO loga segredo, NÃO toca em UI.
// Pattern: Adapter da porta IAuthCredentialRepositoryPort; falhas esperadas
// via Result, I/O do cofre mapeado para ERR_COFRE_INDISPONIVEL.
//
// Contadores de falha vivem no mesmo backend por atomicidade sem nova
// dependência; são estado de segurança, não flags de UX (INV-SEC-05 trata
// das flags biometria/remember_me, fora deste slice).
//
// Dependências: kortex_lib (core/patterns), package:uuid, ports/security da fatia.

import 'dart:convert';
import 'dart:isolate';

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ports/.index.dart';
import '../../domain/security/.index.dart';
import '../../domain/value_objects/.index.dart';

/// Repositório seguro das credenciais do técnico.
final class SecureCredentialStore implements IAuthCredentialRepositoryPort {
  /// Cria o repositório sobre [backend] com [profile] de custo.
  SecureCredentialStore({
    // ignore: prefer_initializing_formals
    required ISecureKeyValue backend,
    this.profile = KdfProfile.standard,
    DateTime Function()? clock,
    this.baseLockout = const Duration(seconds: 30),
    this.maxLockout = const Duration(minutes: 15),
    this.maxAttempts = 3,
    this.rememberedSessionTtl = const Duration(minutes: 15),
  })
        : _backend = backend, // ignore: prefer_initializing_formals
        _now = clock ?? DateTime.now;

  /// Chave do identificador do técnico.
  static const userIdKey = 'sec_user_id';

  /// Chave do hash da senha mestre.
  static const passwordHashKey = 'sec_master_password_hash';

  /// Chave do hash do PIN.
  static const pinHashKey = 'sec_pin_hash';

  /// Chave do contador de falhas do PIN.
  static const pinFailCountKey = 'sec_pin_fail_count';

  /// Chave do bloqueio temporário do PIN (epoch ms UTC).
  static const pinLockedUntilKey = 'sec_pin_locked_until';

  /// Chave do contador de falhas da senha mestre (UC-01.04/A1).
  static const passwordFailCountKey = 'sec_password_fail_count';

  /// Chave do bloqueio temporário da senha mestre (epoch ms UTC).
  static const passwordLockedUntilKey = 'sec_password_locked_until';

  /// Chave da preferência de biometria.
  static const biometricsEnabledKey = 'sec_biometrics_enabled';

  /// Chave da preferência "Lembrar de Mim".
  static const rememberMeKey = 'sec_remember_me';

  /// Chave do último desbloqueio (epoch ms UTC), usada por INV-SEC-08.
  static const lastUnlockAtKey = 'sec_last_unlock_at';

  final ISecureKeyValue _backend;
  final DateTime Function() _now;

  /// Perfil de custo da derivação.
  final KdfProfile profile;

  /// Bloqueio base após esgotar tentativas (dobra a cada falha extra).
  final Duration baseLockout;

  /// Teto do bloqueio temporário.
  final Duration maxLockout;

  /// Tentativas de PIN antes do bloqueio.
  final int maxAttempts;

  /// TTL da sessão lembrada (INV-SEC-08); default 15 minutos.
  final Duration rememberedSessionTtl;

  @override
  Future<IResult<String, ValidationError>> saveCredentials({
    required MasterPassword password,
    required SecurityPin pin,
  }) async {
    try {
      final userId = const Uuid().v4();
      final iterations = profile.iterations;
      final passwordBytes = utf8.encode(password.value);
      final pinBytes = utf8.encode(pin.value);
      final (passwordEncoded, pinEncoded) = await Isolate.run(() {
        final passwordHash = CredentialHash.create(
          password: passwordBytes,
          iterations: iterations,
        );
        final pinHash = CredentialHash.create(
          password: pinBytes,
          iterations: iterations,
        );
        return (passwordHash.encode(), pinHash.encode());
      });
      await _backend.write(userIdKey, userId);
      await _backend.write(passwordHashKey, passwordEncoded);
      await _backend.write(pinHashKey, pinEncoded);
      await _backend.delete(pinFailCountKey);
      await _backend.delete(pinLockedUntilKey);
      return Success(userId);
    } on Exception catch (cause) {
      return Failure(
        ValidationError(
          code: AuthFailureCodes.storeUnavailable,
          message: 'Cofre indisponível. Tente novamente.',
          details: cause.toString(),
        ),
      );
    }
  }

  @override
  Future<IResult<bool, ValidationError>> verifyPin(String attempt) async {
    try {
      final stored = await _backend.read(pinHashKey);
      if (stored == null) {
        return const Failure(
          ValidationError(
            code: AuthFailureCodes.noCredentials,
            message: 'Nenhuma credencial cadastrada neste aparelho.',
          ),
        );
      }
      if (await _isLockedOut()) {
        return const Failure(
          ValidationError(
            code: AuthFailureCodes.pinLockedOut,
            message: 'PIN bloqueado temporariamente. Tente mais tarde.',
          ),
        );
      }
      final hash = CredentialHash.parse(stored);
      final attemptBytes = utf8.encode(attempt);
      final matched = await Isolate.run(() => hash.matches(attemptBytes));
      if (matched) {
        await _backend.delete(pinFailCountKey);
        await _backend.delete(pinLockedUntilKey);
        return const Success(true);
      }
      final failures = await _registerPinFailure();
      if (failures >= maxAttempts) {
        return const Failure(
          ValidationError(
            code: AuthFailureCodes.pinLockedOut,
            message: 'PIN bloqueado temporariamente. Tente mais tarde.',
          ),
        );
      }
      return const Failure(
        ValidationError(
          code: AuthFailureCodes.pinAttemptsLeft,
          message: 'PIN incorreto. Verifique os dígitos.',
        ),
      );
    } on FormatException catch (cause) {
      return Failure(
        ValidationError(
          code: AuthFailureCodes.storeUnavailable,
          message: 'Cofre indisponível. Tente novamente.',
          details: cause.toString(),
        ),
      );
    } on Exception catch (cause) {
      return Failure(
        ValidationError(
          code: AuthFailureCodes.storeUnavailable,
          message: 'Cofre indisponível. Tente novamente.',
          details: cause.toString(),
        ),
      );
    }
  }

  @override
  Future<IResult<bool, ValidationError>> verifyPassword(
    String attempt,
  ) async {
    try {
      final stored = await _backend.read(passwordHashKey);
      if (stored == null) {
        return const Failure(
          ValidationError(
            code: AuthFailureCodes.noCredentials,
            message: 'Nenhuma credencial cadastrada neste aparelho.',
          ),
        );
      }
      if (await _isPasswordLockedOut()) {
        return const Failure(
          ValidationError(
            code: AuthFailureCodes.passwordLockedOut,
            message: 'Senha bloqueada temporariamente. Tente mais tarde.',
          ),
        );
      }
      final hash = CredentialHash.parse(stored);
      final attemptBytes = utf8.encode(attempt);
      final matched = await Isolate.run(() => hash.matches(attemptBytes));
      if (matched) {
        await _backend.delete(passwordFailCountKey);
        await _backend.delete(passwordLockedUntilKey);
        return const Success(true);
      }
      final failures = await _registerPasswordFailure();
      if (failures >= maxAttempts) {
        return const Failure(
          ValidationError(
            code: AuthFailureCodes.passwordLockedOut,
            message: 'Senha bloqueada temporariamente. Tente mais tarde.',
          ),
        );
      }
      return const Failure(
        ValidationError(
          code: AuthFailureCodes.wrongPassword,
          message: 'Senha incorreta.',
        ),
      );
    } on FormatException catch (cause) {
      return Failure(
        ValidationError(
          code: AuthFailureCodes.storeUnavailable,
          message: 'Cofre indisponível. Tente novamente.',
          details: cause.toString(),
        ),
      );
    } on Exception catch (cause) {
      return Failure(
        ValidationError(
          code: AuthFailureCodes.storeUnavailable,
          message: 'Cofre indisponível. Tente novamente.',
          details: cause.toString(),
        ),
      );
    }
  }

  @override
  Future<IResult<bool, ValidationError>> hasCredentials() async {
    try {
      final stored = await _backend.read(passwordHashKey);
      return Success(stored != null);
    } on Exception catch (cause) {
      return Failure(_storeUnavailable(cause));
    }
  }

  @override
  Future<IResult<bool, ValidationError>> isBiometricsEnabled() async {
    return _readBool(biometricsEnabledKey);
  }

  @override
  Future<IResult<bool, ValidationError>> setBiometricsEnabled(
    bool enabled,
  ) async {
    return _writeBool(biometricsEnabledKey, enabled);
  }

  @override
  Future<IResult<bool, ValidationError>> isRememberMeEnabled() async {
    return _readBool(rememberMeKey);
  }

  @override
  Future<IResult<bool, ValidationError>> setRememberMe(bool enabled) async {
    return _writeBool(rememberMeKey, enabled);
  }

  @override
  Future<IResult<bool, ValidationError>> markUnlocked() async {
    try {
      await _backend.write(
        lastUnlockAtKey,
        '${_now().millisecondsSinceEpoch}',
      );
      return const Success(true);
    } on Exception catch (cause) {
      return Failure(_storeUnavailable(cause));
    }
  }

  @override
  Future<IResult<bool, ValidationError>> hasValidRememberedSession() async {
    try {
      final remember = await _backend.read(rememberMeKey);
      if (remember != 'true') return const Success(false);
      final raw = await _backend.read(lastUnlockAtKey);
      if (raw == null) return const Success(false);
      final epochMs = int.tryParse(raw);
      if (epochMs == null) return const Success(false);
      final unlockedAt = DateTime.fromMillisecondsSinceEpoch(epochMs);
      final valid = _now().difference(unlockedAt) <= rememberedSessionTtl;
      return Success(valid);
    } on Exception catch (cause) {
      return Failure(_storeUnavailable(cause));
    }
  }

  @override
  Future<IResult<bool, ValidationError>> resetPin({
    required SecurityPin newPin,
  }) async {
    try {
      final hasCreds = await _backend.read(pinHashKey);
      if (hasCreds == null) {
        return const Failure(
          ValidationError(
            code: AuthFailureCodes.noCredentials,
            message: 'Nenhuma credencial cadastrada neste aparelho.',
          ),
        );
      }
      final iterations = profile.iterations;
      final pinBytes = utf8.encode(newPin.value);
      final pinEncoded = await Isolate.run(
        () => CredentialHash.create(
          password: pinBytes,
          iterations: iterations,
        ).encode(),
      );
      await _backend.write(pinHashKey, pinEncoded);
      await _backend.delete(pinFailCountKey);
      await _backend.delete(pinLockedUntilKey);
      return const Success(true);
    } on Exception catch (cause) {
      return Failure(_storeUnavailable(cause));
    }
  }

  @override
  Future<IResult<bool, ValidationError>> clearAll() async {
    try {
      await _backend.delete(userIdKey);
      await _backend.delete(passwordHashKey);
      await _backend.delete(pinHashKey);
      await _backend.delete(pinFailCountKey);
      await _backend.delete(pinLockedUntilKey);
      await _backend.delete(passwordFailCountKey);
      await _backend.delete(passwordLockedUntilKey);
      await _backend.delete(biometricsEnabledKey);
      await _backend.delete(rememberMeKey);
      await _backend.delete(lastUnlockAtKey);
      return const Success(true);
    } on Exception catch (cause) {
      return Failure(_storeUnavailable(cause));
    }
  }

  Future<IResult<bool, ValidationError>> _readBool(String key) async {
    try {
      final raw = await _backend.read(key);
      return Success(raw == 'true');
    } on Exception catch (cause) {
      return Failure(_storeUnavailable(cause));
    }
  }

  Future<IResult<bool, ValidationError>> _writeBool(
    String key,
    bool value,
  ) async {
    try {
      await _backend.write(key, value ? 'true' : 'false');
      return const Success(true);
    } on Exception catch (cause) {
      return Failure(_storeUnavailable(cause));
    }
  }

  ValidationError _storeUnavailable(Object cause) {
    return ValidationError(
      code: AuthFailureCodes.storeUnavailable,
      message: 'Cofre indisponível. Tente novamente.',
      details: cause.toString(),
    );
  }

  Future<bool> _isLockedOut() async {
    final raw = await _backend.read(pinLockedUntilKey);
    if (raw == null) {
      return false;
    }
    final epochMs = int.tryParse(raw);
    if (epochMs == null) {
      return false;
    }
    final lockedUntil = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return _now().isBefore(lockedUntil);
  }

  Future<int> _registerPinFailure() async {
    final raw = await _backend.read(pinFailCountKey);
    final failures = (int.tryParse(raw ?? '') ?? 0) + 1;
    await _backend.write(pinFailCountKey, '$failures');
    if (failures >= maxAttempts) {
      final extra = failures - maxAttempts;
      final backoff = baseLockout * (1 << extra);
      final capped = backoff > maxLockout ? maxLockout : backoff;
      final lockedUntil = _now().add(capped);
      await _backend.write(
        pinLockedUntilKey,
        '${lockedUntil.millisecondsSinceEpoch}',
      );
    }
    return failures;
  }

  Future<bool> _isPasswordLockedOut() async {
    final raw = await _backend.read(passwordLockedUntilKey);
    if (raw == null) return false;
    final epochMs = int.tryParse(raw);
    if (epochMs == null) return false;
    final lockedUntil = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return _now().isBefore(lockedUntil);
  }

  Future<int> _registerPasswordFailure() async {
    final raw = await _backend.read(passwordFailCountKey);
    final failures = (int.tryParse(raw ?? '') ?? 0) + 1;
    await _backend.write(passwordFailCountKey, '$failures');
    if (failures >= maxAttempts) {
      final extra = failures - maxAttempts;
      final backoff = baseLockout * (1 << extra);
      final capped = backoff > maxLockout ? maxLockout : backoff;
      final lockedUntil = _now().add(capped);
      await _backend.write(
        passwordLockedUntilKey,
        '${lockedUntil.millisecondsSinceEpoch}',
      );
    }
    return failures;
  }

  /// Redigido de propósito: repositório jamais aparece em log (INV-SEC-06).
  @override
  String toString() => 'SecureCredentialStore(redacted)';
}
