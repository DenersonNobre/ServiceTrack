import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/main.dart';
import 'package:service_track/modules/auth/domain/ports/auth_credential_repository_port.dart';
import 'package:service_track/modules/auth/domain/value_objects/auth_credentials.dart';

final class _FakeCredentialRepository implements IAuthCredentialRepositoryPort {
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
  Future<IResult<bool, ValidationError>> clearAll() async => const Success(true);
}

void main() {
  testWidgets('Smoke test inicial da aplicacao ServiceTrack', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ServiceTrackApp(credentialRepository: _FakeCredentialRepository()),
    );
    expect(find.text('Crie seu acesso'), findsOneWidget);
  });
}
