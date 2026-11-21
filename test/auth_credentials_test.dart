// Teste de credenciais do onboarding (UC-01.01, TASK-01).
//
// SRP: cobre os Value Objects TechnicianName, ContactEmail,
// MasterPassword e SecurityPin segundo o Gherkin do épico.
// Não testa persistência, tela ou biometria.

import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/auth/domain/value_objects/.index.dart';

void main() {
  group('TechnicianName', () {
    test('aceita nome valido', () {
      final result = TechnicianName.tryCreate('Rodrigo Silva');
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()!.value, 'Rodrigo Silva');
    });

    test('rejeita nome vazio com ERR_NOME_OBRIGATORIO', () {
      final result = TechnicianName.tryCreate('');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, 'ERR_NOME_OBRIGATORIO');
    });

    test('rejeita nome so com espacos', () {
      final result = TechnicianName.tryCreate('   ');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, 'ERR_NOME_OBRIGATORIO');
    });
  });

  group('ContactEmail', () {
    test('aceita email valido', () {
      final result = ContactEmail.tryCreate('rodrigo@clima.com');
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()!.value, 'rodrigo@clima.com');
    });

    test('normaliza caixa e espacos', () {
      final result = ContactEmail.tryCreate('  RODRIGO@CLIMA.COM  ');
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()!.value, 'rodrigo@clima.com');
    });

    test('rejeita email invalido com ERR_EMAIL_INVALIDO', () {
      final result = ContactEmail.tryCreate('invalido');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, 'ERR_EMAIL_INVALIDO');
    });

    test('rejeita email vazio com ERR_EMAIL_INVALIDO', () {
      final result = ContactEmail.tryCreate('');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, 'ERR_EMAIL_INVALIDO');
    });
  });

  group('MasterPassword', () {
    test('aceita senha forte', () {
      final result = MasterPassword.tryCreate('Segura@2026');
      expect(result.isSuccess, isTrue);
    });

    test('rejeita senha curta com ERR_SENHA_CURTA', () {
      final result = MasterPassword.tryCreate('123');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, 'ERR_SENHA_CURTA');
    });

    test('rejeita senha vazia com ERR_SENHA_CURTA', () {
      final result = MasterPassword.tryCreate('');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, 'ERR_SENHA_CURTA');
    });
  });

  group('SecurityPin', () {
    test('aceita PIN de 4 digitos', () {
      final result = SecurityPin.tryCreate('1234');
      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()!.value, '1234');
    });

    test('aceita PIN de 6 digitos', () {
      final result = SecurityPin.tryCreate('123456');
      expect(result.isSuccess, isTrue);
    });

    test('rejeita PIN curto com ERR_PIN_INVALIDO', () {
      final result = SecurityPin.tryCreate('12');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, 'ERR_PIN_INVALIDO');
    });

    test('rejeita PIN com letra com ERR_PIN_INVALIDO', () {
      final result = SecurityPin.tryCreate('12a4');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, 'ERR_PIN_INVALIDO');
    });

    test('rejeita PIN longo com ERR_PIN_INVALIDO', () {
      final result = SecurityPin.tryCreate('1234567');
      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()!.code, 'ERR_PIN_INVALIDO');
    });
  });
}
