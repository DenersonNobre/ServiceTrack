import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/auth/domain/ports/.index.dart';
import 'package:service_track/modules/auth/domain/value_objects/.index.dart';
import 'package:service_track/modules/auth/features/app_entry/.index.dart';

final class _FakeAuthRepo implements IAuthCredentialRepositoryPort {
  _FakeAuthRepo({
    this.hasCreds = false,
    this.rememberValid = false,
    this.failHasCreds = false,
  });
  bool hasCreds;
  bool rememberValid;
  bool failHasCreds;

  @override
  Future<IResult<bool, ValidationError>> hasCredentials() async {
    if (failHasCreds) {
      return const Failure(
        ValidationError(code: 'ERR_COFRE_INDISPONIVEL', message: 'x'),
      );
    }
    return Success(hasCreds);
  }

  @override
  Future<IResult<bool, ValidationError>> hasValidRememberedSession() async =>
      Success(rememberValid);

  @override
  Future<IResult<String, ValidationError>> saveCredentials({
    required MasterPassword password,
    required SecurityPin pin,
  }) async => const Success('user-1');
  @override
  Future<IResult<bool, ValidationError>> verifyPin(String attempt) async =>
      const Success(true);
  @override
  Future<IResult<bool, ValidationError>> verifyPassword(String attempt) async =>
      const Success(true);
  @override
  Future<IResult<bool, ValidationError>> isBiometricsEnabled() async =>
      const Success(false);
  @override
  Future<IResult<bool, ValidationError>> setBiometricsEnabled(bool enabled) async =>
      const Success(true);
  @override
  Future<IResult<bool, ValidationError>> isRememberMeEnabled() async =>
      const Success(false);
  @override
  Future<IResult<bool, ValidationError>> setRememberMe(bool enabled) async =>
      const Success(true);
  @override
  Future<IResult<bool, ValidationError>> markUnlocked() async =>
      const Success(true);
  @override
  Future<IResult<bool, ValidationError>> resetPin({
    required SecurityPin newPin,
  }) async => const Success(true);

  @override
  Future<IResult<bool, ValidationError>> clearAll() async => const Success(true);
}

void main() {
  group('ResolveInitialRouteUseCase', () {
    test('sem credenciais -> onboarding', () async {
      final useCase = ResolveInitialRouteUseCase(repo: _FakeAuthRepo());
      expect(await useCase.execute(), AppEntryRoute.onboarding);
    });

    test('com credenciais -> lock (fail-closed)', () async {
      final useCase = ResolveInitialRouteUseCase(
        repo: _FakeAuthRepo(hasCreds: true),
      );
      expect(await useCase.execute(), AppEntryRoute.lock);
    });

    test('com credenciais e sessão lembrada válida -> home', () async {
      final useCase = ResolveInitialRouteUseCase(
        repo: _FakeAuthRepo(hasCreds: true, rememberValid: true),
      );
      expect(await useCase.execute(), AppEntryRoute.home);
    });

    test('erro ao ler credenciais -> lock (A5 fail-closed)', () async {
      final useCase = ResolveInitialRouteUseCase(
        repo: _FakeAuthRepo(failHasCreds: true),
      );
      expect(await useCase.execute(), AppEntryRoute.lock);
    });
  });
}
