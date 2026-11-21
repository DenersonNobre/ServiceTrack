// Testes da tela de Onboarding (UC-01.01, TASK-03).
//
// SRP: valida renderização, tokens, validação por VO e submissão
// bem-sucedida da tela de onboarding. Não testa persistência real
// nem plugin; usa dublê da porta de credenciais.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/kortex.dart';
import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:service_track/modules/auth/domain/ports/.index.dart';
import 'package:service_track/modules/auth/domain/value_objects/.index.dart';
import 'package:service_track/modules/auth/ui/onboarding/.index.dart';

final class _FakeCredentialRepository implements IAuthCredentialRepositoryPort {
  int saveCalls = 0;
  MasterPassword? lastPassword;
  SecurityPin? lastPin;

  @override
  Future<IResult<String, ValidationError>> saveCredentials({
    required MasterPassword password,
    required SecurityPin pin,
  }) async {
    saveCalls++;
    lastPassword = password;
    lastPin = pin;
    return const Success('user-1');
  }

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

Widget _buildApp(_FakeCredentialRepository repo) {
  return MaterialApp(
    home: KortexScope(
      providers: [
        KortexProvider<OnboardingController>(
          create: (_) => OnboardingController(repository: repo),
          dispose: (c) => c.dispose(),
        ),
      ],
      child: const OnboardingPage(),
    ),
  );
}

void main() {
  testWidgets('renderiza campos e CTA com token Deep Petrol Green', (
    WidgetTester tester,
  ) async {
    final repo = _FakeCredentialRepository();
    await tester.pumpWidget(_buildApp(repo));

    expect(find.text('Crie seu acesso'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nome completo'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'E-mail'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Senha mestre'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'PIN (4 a 6 dígitos)'), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final style = button.style!;
    final bg = style.backgroundColor?.resolve({});
    expect(bg, const Color(0xFF115E59));

    final nameFieldSize = tester.getSize(find.widgetWithText(TextFormField, 'Nome completo'));
    expect(nameFieldSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets('mostra erros dos VOs quando submissao invalida', (
    WidgetTester tester,
  ) async {
    final repo = _FakeCredentialRepository();
    await tester.pumpWidget(_buildApp(repo));

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome do técnico.'), findsOneWidget);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('A senha deve ter ao menos 8 caracteres.'), findsOneWidget);
    expect(find.text('O PIN deve ter de 4 a 6 dígitos numéricos.'), findsOneWidget);
    expect(repo.saveCalls, 0);
  });

  testWidgets('submete credenciais validas e reporta sucesso', (
    WidgetTester tester,
  ) async {
    final repo = _FakeCredentialRepository();
    await tester.pumpWidget(_buildApp(repo));

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome completo'), 'Rodrigo Silva');
    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'rodrigo@clima.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha mestre'), 'Segura@2026');
    await tester.enterText(find.widgetWithText(TextFormField, 'PIN (4 a 6 dígitos)'), '1234');

    await tester.tap(find.text('Criar conta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.saveCalls, 1);
    expect(repo.lastPassword?.value, 'Segura@2026');
    expect(repo.lastPin?.value, '1234');
    expect(find.text('Conta criada com sucesso.'), findsOneWidget);
  });
}
