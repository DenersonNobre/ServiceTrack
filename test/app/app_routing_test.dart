import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/app/app_pages.dart';
import 'package:service_track/app/app_relock_watcher.dart';
import 'package:service_track/app/app_routes.dart';
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
  group('AppRoutes', () {
    test('declara rotas canônicas', () {
      expect(AppRoutes.initial, '/');
      expect(AppRoutes.onboarding, '/onboarding');
      expect(AppRoutes.lock, '/lock');
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.recovery, '/recovery');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.customers, '/customers');
      expect(AppRoutes.workOrders, '/work-orders');
      expect(AppRoutes.newWorkOrder, '/work-orders/new');
      expect(AppRoutes.checklists, '/checklists');
      expect(AppRoutes.settings, '/settings');
    });
  });

  group('AppPages', () {
    test('onGenerateRoute resolve rotas de autenticação e gate', () {
      final services = AppServices(
        credentialStore: _FakeCredentialRepo(),
        biometricAuth: _FakeBiometricAuth(),
        locationService: _FakeLocationService(),
      );
      final pages = AppPages(services: services);

      expect(
        pages.onGenerateRoute(const RouteSettings(name: AppRoutes.initial)),
        isNotNull,
      );
      expect(
        pages.onGenerateRoute(const RouteSettings(name: AppRoutes.onboarding)),
        isNotNull,
      );
      expect(
        pages.onGenerateRoute(const RouteSettings(name: AppRoutes.lock)),
        isNotNull,
      );
      expect(
        pages.onGenerateRoute(const RouteSettings(name: AppRoutes.recovery)),
        isNotNull,
      );
    });
  });

  group('AppGate', () {
    testWidgets('exibe spinner e despacha para onboarding quando sem credenciais', (
      tester,
    ) async {
      final services = AppServices(
        credentialStore: _FakeCredentialRepo(hasCreds: false),
        biometricAuth: _FakeBiometricAuth(),
        locationService: _FakeLocationService(),
      );

      final navKey = GlobalKey<NavigatorState>();
      final pages = AppPages(services: services, navigatorKey: navKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          initialRoute: AppRoutes.initial,
          onGenerateRoute: pages.onGenerateRoute,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Crie seu acesso'), findsOneWidget);
    });

    testWidgets('despacha para lock quando possui credenciais', (
      tester,
    ) async {
      final services = AppServices(
        credentialStore: _FakeCredentialRepo(hasCreds: true),
        biometricAuth: _FakeBiometricAuth(),
        locationService: _FakeLocationService(),
      );

      final navKey = GlobalKey<NavigatorState>();
      final pages = AppPages(services: services, navigatorKey: navKey);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          initialRoute: AppRoutes.initial,
          onGenerateRoute: pages.onGenerateRoute,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Digite seu PIN'), findsOneWidget);
    });
  });

  group('AppRelockWatcher', () {
    testWidgets('dispara relock após tempo limite em background', (
      tester,
    ) async {
      var relockTriggered = false;
      var simulatedTime = DateTime(2026, 1, 1, 12, 0);

      final widget = AppRelockWatcher(
        clock: () => simulatedTime,
        timeout: const Duration(minutes: 5),
        onRelock: () => relockTriggered = true,
        child: const Text('Conteúdo'),
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      expect(find.text('Conteúdo'), findsOneWidget);

      final state = tester.state<State<AppRelockWatcher>>(
        find.byType(AppRelockWatcher),
      ) as WidgetsBindingObserver;

      // App vai para background
      state.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Avança menos de 5 min
      simulatedTime = simulatedTime.add(const Duration(minutes: 4));
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(relockTriggered, isFalse);

      // App vai novamente para background
      state.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Avança mais de 5 min
      simulatedTime = simulatedTime.add(const Duration(minutes: 5, seconds: 1));
      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(relockTriggered, isTrue);
    });
  });
}
