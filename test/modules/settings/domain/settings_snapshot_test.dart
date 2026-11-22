import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/settings/.index.dart';

void main() {
  group('UC-07.01 - SettingsSnapshot & SettingKey', () {
    test('defaults seguros: checklist exigido, documento não exigido', () {
      final snapshot = SettingsSnapshot.defaults();

      expect(snapshot.requireChecklistTemplate, isTrue);
      expect(snapshot.requireReceiverDocument, isFalse);
    });

    test('withValue altera apenas a chave informada', () {
      final snapshot = SettingsSnapshot.defaults().withValue(
        SettingKey.requireReceiverDocument,
        true,
      );

      expect(snapshot.requireChecklistTemplate, isTrue);
      expect(snapshot.requireReceiverDocument, isTrue);
    });

    test('snapshot preenche defaults para chaves ausentes', () {
      final snapshot = SettingsSnapshot({
        SettingKey.requireChecklistTemplate: false,
      });

      expect(snapshot.requireChecklistTemplate, isFalse);
      expect(snapshot.requireReceiverDocument, isFalse);
    });

    test(
      'fromStorageKey reconhece o catálogo e rejeita chave desconhecida',
      () {
        expect(
          SettingKey.fromStorageKey('require_checklist_template'),
          SettingKey.requireChecklistTemplate,
        );
        expect(
          SettingKey.fromStorageKey('require_receiver_document'),
          SettingKey.requireReceiverDocument,
        );
        expect(SettingKey.fromStorageKey('chave_inexistente'), isNull);
      },
    );
  });
}
