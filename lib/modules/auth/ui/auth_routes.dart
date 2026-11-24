// Rotas e bindings Kortex do módulo de autenticação local (ADR-002 / UC-06.05 T1).
//
// SRP: compor rotas e escopos Kortex das telas de onboarding, bloqueio e
// recuperação de PIN. Não implementa regra de negócio nem conhece o shell.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../app/app_services.dart';
import '../../../core/ui/app_scoped_route.dart';
import '../domain/ports/auth_credential_repository_port.dart';
import '../domain/ports/biometric_auth_port.dart';
import '../features/biometric_unlock/biometric_unlock_use_case.dart';
import '../features/recovery/pin_recovery_use_case.dart';
import 'lock/lock_controller.dart';
import 'lock/lock_page.dart';
import 'onboarding/onboarding_controller.dart';
import 'onboarding/onboarding_page.dart';
import 'recovery/pin_recovery_controller.dart';
import 'recovery/pin_recovery_page.dart';

/// Bindings de navegação do bounded context de autenticação local.
final class AuthRoutes {
  /// Cria as rotas de autenticação recebendo apenas as portas do módulo (ISP).
  const AuthRoutes({
    required this.credentialRepository,
    required this.biometricAuth,
  });

  factory AuthRoutes.fromServices(AppServices services) {
    return AuthRoutes(
      credentialRepository: services.credentialStore,
      biometricAuth: services.biometricAuth,
    );
  }

  /// Porta de persistência segura de credenciais.
  final IAuthCredentialRepositoryPort credentialRepository;

  /// Porta de autenticação biométrica / credencial do dispositivo.
  final IBiometricAuthPort biometricAuth;

  /// Rota de cadastro inicial (onboarding).
  Route<void> onboarding({required VoidCallback onCompleted}) {
    return appScopedRoute<OnboardingController, void>(
      create: (_) => _createOnboardingController(onCompleted: onCompleted),
      builder: (_, _) => const OnboardingPage(),
    );
  }

  /// Widget raiz de onboarding com [KortexScope] para uso no gate inicial.
  Widget onboardingWidget({required VoidCallback onCompleted}) {
    return KortexScope(
      providers: [
        KortexProvider<OnboardingController>(
          create: (_) => _createOnboardingController(onCompleted: onCompleted),
          dispose: (controller) => controller.dispose(),
        ),
      ],
      child: const OnboardingPage(),
    );
  }

  /// Rota de bloqueio (PIN / biometria).
  Route<void> lock({
    required VoidCallback onUnlocked,
    required VoidCallback onForgotPin,
  }) {
    return appScopedRoute<LockController, void>(
      create: (_) => _createLockController(
        onUnlocked: onUnlocked,
        onForgotPin: onForgotPin,
      ),
      builder: (_, _) => const LockPage(),
    );
  }

  /// Widget raiz de bloqueio com [KortexScope] para uso no gate inicial.
  Widget lockWidget({
    required VoidCallback onUnlocked,
    required VoidCallback onForgotPin,
  }) {
    return KortexScope(
      providers: [
        KortexProvider<LockController>(
          create: (_) => _createLockController(
            onUnlocked: onUnlocked,
            onForgotPin: onForgotPin,
          ),
          dispose: (controller) => controller.dispose(),
        ),
      ],
      child: const LockPage(),
    );
  }

  /// Rota de recuperação de PIN (senha mestre ou credencial do SO).
  Route<void> recovery({required VoidCallback onRecovered}) {
    return appScopedRoute<PinRecoveryController, void>(
      create: (_) => PinRecoveryController(
        useCase: PinRecoveryUseCase(
          repository: credentialRepository,
          biometricAuth: biometricAuth,
        ),
        repository: credentialRepository,
        onRecovered: onRecovered,
      ),
      builder: (_, _) => const PinRecoveryPage(),
    );
  }

  OnboardingController _createOnboardingController({
    required VoidCallback onCompleted,
  }) {
    return OnboardingController(
      repository: credentialRepository,
      onCompleted: () {
        unawaited(credentialRepository.markUnlocked());
        onCompleted();
      },
    );
  }

  LockController _createLockController({
    required VoidCallback onUnlocked,
    required VoidCallback onForgotPin,
  }) {
    return LockController(
      biometricUnlock: BiometricUnlockUseCase(biometricAuth: biometricAuth),
      repository: credentialRepository,
      onUnlocked: onUnlocked,
      onForgotPin: onForgotPin,
    );
  }
}
