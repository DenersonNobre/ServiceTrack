import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/profile/domain/value_objects/technician_profile.dart';

void main() {
  group('TechnicianProfile VOs', () {
    test('CommercialName válido', () {
      final r = CommercialName.tryCreate('  Rodrigo Serviços  ');
      expect(r.isSuccess, isTrue);
      expect(r.getOrNull()!.value, 'Rodrigo Serviços');
    });

    test('CommercialName vazio falha', () {
      final r = CommercialName.tryCreate('   ');
      expect(r.isFailure, isTrue);
    });

    test('WhatsApp válido BR', () {
      final r = WhatsAppNumber.tryCreate('(11) 99999-8888');
      expect(r.isSuccess, isTrue);
      expect(r.getOrNull()!.digits, '11999998888');
    });

    test('WhatsApp inválido falha', () {
      final r = WhatsAppNumber.tryCreate('123');
      expect(r.isFailure, isTrue);
    });

    test('TechnicianProfile.tryCreate normaliza', () {
      final r = TechnicianProfile.tryCreate(
        commercialName: 'Rodrigo',
        whatsapp: '11999998888',
        logoPath: null,
      );
      expect(r.isSuccess, isTrue);
      expect(r.getOrNull()!.commercialName.value, 'Rodrigo');
    });
  });
}
