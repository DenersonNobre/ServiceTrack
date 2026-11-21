// Caso de uso: decisão de desbloqueio por biometria (UC-01.02).
//
// SRP: mapear o resultado biométrico para decisão de navegação/auth, de forma
// fail-closed. Não faz I/O direto nem conhece UI/widgets.
//
// Pattern: Use Case (CQRS-lite) + fail-closed.

import '../../domain/ports/.index.dart';
import '../../domain/value_objects/.index.dart';

/// Decisão de desbloqueio após avaliação biométrica.
enum UnlockDecision {
  /// Acesso liberado para a Home.
  grantHome,

  /// Exigir PIN manual (falha, indisponível, lockout, erro).
  requirePin,

  /// Permanecer na tela de PIN/bloqueio (cancelamento explícito).
  stayOnPin,
}

/// Avalia biometria no boot/abertura e retorna decisão fail-closed.
final class BiometricUnlockUseCase {
  /// Cria o caso de uso com a porta biométrica.
  const BiometricUnlockUseCase({required this.biometricAuth});

  /// Porta biométrica (DIP).
  final IBiometricAuthPort biometricAuth;

  /// Executa a avaliação. Apenas [BiometricAuthResult.success] libera Home.
  Future<UnlockDecision> execute({required bool biometricsEnabled}) async {
    if (!biometricsEnabled) return UnlockDecision.requirePin;

    final canAuth = await biometricAuth.canAuthenticate();
    if (!canAuth) return UnlockDecision.requirePin;

    final result = await biometricAuth.authenticate();
    return switch (result) {
      BiometricAuthResult.success => UnlockDecision.grantHome,
      BiometricAuthResult.canceled => UnlockDecision.stayOnPin,
      BiometricAuthResult.failure => UnlockDecision.requirePin,
      BiometricAuthResult.unavailable => UnlockDecision.requirePin,
      BiometricAuthResult.lockoutTemporary => UnlockDecision.requirePin,
      BiometricAuthResult.lockoutPermanent => UnlockDecision.requirePin,
      BiometricAuthResult.error => UnlockDecision.requirePin,
    };
  }
}
