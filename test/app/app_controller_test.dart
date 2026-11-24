import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/app/app.dart';
import 'package:service_track/app/app_controller.dart';
import 'package:service_track/app/app_services.dart';
import 'package:service_track/modules/auth/domain/ports/auth_credential_repository_port.dart';
import 'package:service_track/modules/auth/domain/ports/biometric_auth_port.dart';
import 'package:service_track/modules/auth/domain/value_objects/biometric_auth_result.dart';
import 'package:service_track/modules/auth/domain/value_objects/master_password.dart';
import 'package:service_track/modules/auth/domain/value_objects/security_pin.dart';
import 'package:service_track/modules/work_orders/domain/ports/location_service_port.dart';
import 'package:service_track/modules/work_orders/domain/value_objects/geo_point.dart';

final class _FakeCredentialRepo implements IAuthCredentialRepositoryPort {
  _FakeCredentialRepo({this.hasCreds = false});
  final bool hasCreds;

  @override
  Future<IResult<bool, ValidationError>> hasCredentials() async =>
      Success(hasCreds);

  @override
  Future<IResult<String, ValidationError>> saveCredentials({
    required MasterPassword password,
    required SecurityPin pin,
  }) async =>
      const Success('user-1');

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
  ) async =>
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
  Future<IResult<bool, ValidationError>> hasValidRememberedSession() async =>
      const Success(false);

  @override
  Future<IResult<bool, ValidationError>> resetPin({
    required SecurityPin newPin,
  }) async =>
      const Success(true);

  @override
  Future<IResult<bool, ValidationError>> clearAll() async =>
      const Success(true);
}

final class _FakeBiometricAuth implements IBiometricAuthPort {
  @override
  Future<bool> canAuthenticate() async => false;

  @override
  Future<BiometricAuthResult> authenticate() async =>
      BiometricAuthResult.unavailable;

  @override
  Future<BiometricAuthResult> authenticateDeviceCredential() async =>
      BiometricAuthResult.unavailable;
}

final class _FakeLocationService implements ILocationServicePort {
  @override
  Future<IResult<GeoPoint, ValidationError>> getCurrentLocation() async =>
      const Failure(ValidationError(code: 'ERR_NO_LOC', message: 'Sem gps'));
}

void main() {
  group('AppController', () {
    test('inicializa com servicos, navigatorKey, pages e themeMode padrão', () {
      final services = AppServices(
        credentialStore: _FakeCredentialRepo(),
        biometricAuth: _FakeBiometricAuth(),
        locationService: _FakeLocationService(),
      );
      final navKey = GlobalKey<NavigatorState>();

      final controller = AppController(
        services: services,
        navigatorKey: navKey,
      );

      expect(controller.services, same(services));
      expect(controller.navigatorKey, same(navKey));
      expect(controller.pages, isNotNull);
      expect(controller.themeMode.value, ThemeMode.light);

      controller.dispose();
    });

    test('fromDatabase fabrica AppServices padrão quando omitido', () {
      final controller = AppController.fromDatabase();
      expect(controller.services, isNotNull);
      expect(controller.navigatorKey, isNotNull);
      expect(controller.pages, isNotNull);
      controller.dispose();
    });
  });

  group('App Widget (Stateless)', () {
    testWidgets('renderiza KortexMaterialApp e provê AppController e AppServices no contexto', (
      tester,
    ) async {
      final services = AppServices(
        credentialStore: _FakeCredentialRepo(hasCreds: false),
        biometricAuth: _FakeBiometricAuth(),
        locationService: _FakeLocationService(),
      );
      final controller = AppController(services: services);

      await tester.pumpWidget(App(controller: controller));

      expect(find.byType(App), findsOneWidget);
      expect(tester.widget(find.byType(App)), isA<StatelessWidget>());

      final element = tester.element(find.byType(MaterialApp));
      final resolvedController = element.readKortex<AppController>();
      final resolvedServices = element.readKortex<AppServices>();

      expect(resolvedController, same(controller));
      expect(resolvedServices, same(services));

      await tester.pumpAndSettle();
      controller.dispose();
    });
  });
}
