// Testes de widget para AuthRoutes (ADR-002 / UC-06.05 T1).

import 'dart:async';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/auth/domain/ports/.index.dart';
import 'package:service_track/modules/auth/domain/value_objects/.index.dart';
import 'package:service_track/modules/auth/ui/auth_routes.dart';
import 'package:service_track/modules/auth/ui/lock/lock_page.dart';

final class _FakeBio implements IBiometricAuthPort {
  @override
  Future<bool> canAuthenticate() async => false;

  @override
  Future<BiometricAuthResult> authenticate() async =>
      BiometricAuthResult.unavailable;

  @override
  Future<BiometricAuthResult> authenticateDeviceCredential() async =>
      BiometricAuthResult.unavailable;
}

final class _FakeRepo implements IAuthCredentialRepositoryPort {
  @override
  Future<IResult<String, ValidationError>> saveCredentials({
    required MasterPassword password,
    required SecurityPin pin,
  }) async => const Success('user-1');

  @override
  Future<IResult<bool, ValidationError>> hasCredentials() async =>
      const Success(true);

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
  Future<IResult<bool, ValidationError>> setBiometricsEnabled(
    bool enabled,
  ) async => const Success(true);

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
  Future<IResult<bool, ValidationError>> hasValidRememberedSession() async =>
      const Success(false);

  @override
  Future<IResult<bool, ValidationError>> resetPin({
    required SecurityPin newPin,
  }) async => const Success(true);

  @override
  Future<IResult<bool, ValidationError>> clearAll() async =>
      const Success(true);
}

void main() {
  late AuthRoutes routes;

  setUp(() {
    routes = AuthRoutes(
      credentialRepository: _FakeRepo(),
      biometricAuth: _FakeBio(),
    );
  });

  testWidgets('OPS-AUTH-ROUTES - onboarding monta KortexScope e renderiza tela',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                unawaited(
                  Navigator.of(context).push(
                    routes.onboarding(onCompleted: () {}),
                  ),
                );
              },
              child: const Text('abrir-onboarding'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir-onboarding'));
    await tester.pumpAndSettle();

    expect(find.text('Crie seu acesso'), findsOneWidget);
  });

  testWidgets('OPS-AUTH-ROUTES - lock monta KortexScope e renderiza tela',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                unawaited(
                  Navigator.of(context).push(
                    routes.lock(onUnlocked: () {}, onForgotPin: () {}),
                  ),
                );
              },
              child: const Text('abrir-lock'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir-lock'));
    await tester.pumpAndSettle();

    expect(find.byType(LockPage), findsOneWidget);
  });

  testWidgets('OPS-AUTH-ROUTES - recovery monta KortexScope e renderiza tela',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                unawaited(
                  Navigator.of(context).push(
                    routes.recovery(onRecovered: () {}),
                  ),
                );
              },
              child: const Text('abrir-recovery'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir-recovery'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar PIN'), findsOneWidget);
  });
}
