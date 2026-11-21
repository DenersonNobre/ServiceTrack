// Resolve a rota inicial do app (UC-01.02, INV-SEC-08/A5).
//
// SRP: decidir onboarding/lock/home com base em credenciais e sessão lembrada.
// Não navega nem conhece widgets.
//
// Pattern: Use Case; fail-closed em erro/estado desconhecido.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../../domain/ports/.index.dart';

/// Rota inicial decidida no boot.
enum AppEntryRoute {
  /// Primeiro acesso: onboarding.
  onboarding,

  /// Credenciais existem: exigir desbloqueio.
  lock,

  /// Sessão lembrada válida: acesso direto.
  home,
}

/// Decide a rota inicial de forma fail-closed.
final class ResolveInitialRouteUseCase {
  /// Cria o caso de uso com o repositório de credenciais.
  const ResolveInitialRouteUseCase({required this.repo});

  /// Repositório de credenciais/sessão.
  final IAuthCredentialRepositoryPort repo;

  /// Resolve a rota inicial. Erro ou estado ambíguo -> [AppEntryRoute.lock].
  Future<AppEntryRoute> execute() async {
    final hasCreds = await repo.hasCredentials();
    final credsExist = switch (hasCreds) {
      Success<bool, ValidationError>(:final value) => value,
      Failure<bool, ValidationError>() => null,
    };
    if (credsExist == null) return AppEntryRoute.lock;
    if (!credsExist) return AppEntryRoute.onboarding;

    final remembered = await repo.hasValidRememberedSession();
    final rememberedValid = switch (remembered) {
      Success<bool, ValidationError>(:final value) => value,
      Failure<bool, ValidationError>() => false,
    };
    if (rememberedValid) return AppEntryRoute.home;
    return AppEntryRoute.lock;
  }
}
