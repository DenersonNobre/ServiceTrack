import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/customers/domain/value_objects/service_location.dart';

void main() {
  group('ServiceLocation', () {
    test('cria local válido', () {
      final r = ServiceLocation.tryCreate(
        id: 'l1',
        customerId: 'c1',
        label: 'Casa',
        street: 'Rua A',
        number: '10',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        cep: '01001000',
        reference: 'Perto da praça',
      );
      expect(r.isSuccess, isTrue);
      final l = r.getOrNull()!;
      expect(l.label.value, 'Casa');
      expect(l.cep?.digits, '01001000');
    });

    test('rejeita CEP inválido', () {
      final r = ServiceLocation.tryCreate(
        id: 'l1',
        customerId: 'c1',
        label: 'Casa',
        street: 'Rua A',
        number: '10',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        cep: '123',
        reference: '',
      );
      expect(r.isFailure, isTrue);
    });

    test('aceita CEP vazio', () {
      final r = ServiceLocation.tryCreate(
        id: 'l1',
        customerId: 'c1',
        label: 'Casa',
        street: 'Rua A',
        number: '10',
        neighborhood: 'Centro',
        city: 'São Paulo',
        state: 'SP',
        cep: '',
        reference: '',
      );
      expect(r.isSuccess, isTrue);
      expect(r.getOrNull()!.cep, isNull);
    });
  });
}
