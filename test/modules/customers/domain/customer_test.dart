import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/customers/domain/value_objects/customer.dart';

void main() {
  group('Customer', () {
    test('cria cliente válido com CPF', () {
      final r = Customer.tryCreate(
        id: 'c1',
        name: 'Maria Silva',
        document: '52998224725',
        whatsapp: '11999998888',
        email: 'maria@exemplo.com',
        notes: 'Cliente VIP',
      );
      expect(r.isSuccess, isTrue);
      final c = r.getOrNull()!;
      expect(c.name.value, 'Maria Silva');
      expect(c.document?.digits, '52998224725');
    });

    test('rejeita documento inválido', () {
      final r = Customer.tryCreate(
        id: 'c1',
        name: 'Maria Silva',
        document: '123',
        whatsapp: '11999998888',
        email: '',
        notes: '',
      );
      expect(r.isFailure, isTrue);
    });

    test('aceita cliente sem documento', () {
      final r = Customer.tryCreate(
        id: 'c1',
        name: 'Maria Silva',
        document: '',
        whatsapp: '11999998888',
        email: '',
        notes: '',
      );
      expect(r.isSuccess, isTrue);
      expect(r.getOrNull()!.document, isNull);
    });
  });
}
