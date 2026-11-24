import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:service_track/app/app.dart';
import 'package:service_track/app/app_services.dart';
import 'package:service_track/modules/auth/data/biometric/local_auth_biometric_adapter.dart';
import 'package:service_track/modules/auth/domain/ports/.index.dart';
import 'package:service_track/modules/auth/domain/value_objects/.index.dart';
import 'package:service_track/modules/work_orders/data/geolocator_location_service.dart';

final class _FakeCredentialRepository implements IAuthCredentialRepositoryPort {
  @override
  Future<IResult<String, ValidationError>> saveCredentials({
    required MasterPassword password,
    required SecurityPin pin,
  }) async => const Success('user-1');

  @override
  Future<IResult<bool, ValidationError>> hasCredentials() async =>
      const Success(false);

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
  testWidgets('Smoke test inicial da aplicacao ServiceTrack', (
    WidgetTester tester,
  ) async {
    final services = AppServices(
      credentialStore: _FakeCredentialRepository(),
      biometricAuth: LocalAuthBiometricAdapter(),
      locationService: GeolocatorLocationService(),
    );

    await tester.pumpWidget(App(services: services));
    await tester.pump();
    expect(find.text('Crie seu acesso'), findsOneWidget);
  });
}
