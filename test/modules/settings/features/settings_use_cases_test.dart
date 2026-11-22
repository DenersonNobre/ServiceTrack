import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/settings/.index.dart';

void main() {
  group('UC-07.01 - Settings use cases', () {
    test('GetSettings retorna defaults', () async {
      final getSettings = GetSettings(repository: MemorySettingsRepository());

      final result = await getSettings.execute();

      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()!.requireChecklistTemplate, isTrue);
      expect(result.getOrNull()!.requireReceiverDocument, isFalse);
    });

    test('UpdateSetting persiste política por chave do catálogo', () async {
      final repository = MemorySettingsRepository();
      final updateSetting = UpdateSetting(repository: repository);

      final result = await updateSetting.execute(
        key: 'require_checklist_template',
        value: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.getOrNull()!.requireChecklistTemplate, isFalse);
      expect(
        (await repository.load()).getOrNull()!.requireChecklistTemplate,
        isFalse,
      );
    });

    test('UpdateSetting rejeita chave fora do catálogo', () async {
      final updateSetting = UpdateSetting(
        repository: MemorySettingsRepository(),
      );

      final result = await updateSetting.execute(
        key: 'chave_inexistente',
        value: true,
      );

      expect(result.isFailure, isTrue);
      expect(result.getOrNullFailure()?.code, SettingsFailureCodes.invalidKey);
    });
  });
}
