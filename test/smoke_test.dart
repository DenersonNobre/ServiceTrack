import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/main.dart';
import 'package:service_track/modules/auth/domain/ports/.index.dart';
import 'package:service_track/modules/auth/domain/value_objects/.index.dart';

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
  Future<IResult<bool, ValidationError>> hasValidRememberedSession() async =>
      const Success(false);

  @override
  Future<IResult<bool, ValidationError>> clearAll() async => const Success(true);
}

void main() {
  testWidgets('Smoke test inicial da aplicacao ServiceTrack', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ServiceTrackApp(credentialRepository: _FakeCredentialRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Crie seu acesso'), findsOneWidget);
  });
}
