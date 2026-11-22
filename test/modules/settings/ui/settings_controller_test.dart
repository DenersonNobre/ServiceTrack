import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/settings/.index.dart';

final class _FailingUpdateRepository implements ISettingsRepositoryPort {
  @override
  Future<IResult<SettingsSnapshot, ValidationError>> load() async =>
      Success(SettingsSnapshot.defaults());

  @override
  Future<IResult<SettingsSnapshot, ValidationError>> update(
    SettingKey key,
    bool value,
  ) async => const Failure(
    ValidationError(
      code: SettingsFailureCodes.persistence,
      message: 'Falha ao salvar.',
    ),
  );
}

void main() {
  group('UC-07.02 - SettingsController', () {
    test('carrega defaults e expõe snapshot', () async {
      final repository = MemorySettingsRepository();
      final controller = SettingsController(
        getSettings: GetSettings(repository: repository),
        updateSetting: UpdateSetting(repository: repository),
      );

      await controller.ensureLoaded();

      expect(controller.loading.value, isFalse);
      expect(controller.snapshot.value.requireChecklistTemplate, isTrue);
      expect(controller.snapshot.value.requireReceiverDocument, isFalse);
      controller.dispose();
    });

    test('atualiza checklist e persiste via use case', () async {
      final repository = MemorySettingsRepository();
      final controller = SettingsController(
        getSettings: GetSettings(repository: repository),
        updateSetting: UpdateSetting(repository: repository),
      );
      await controller.ensureLoaded();

      await controller.setRequireChecklistTemplate(false);

      expect(controller.snapshot.value.requireChecklistTemplate, isFalse);
      expect(controller.success.value, isNotNull);
      expect(
        (await repository.load()).getOrNull()!.requireChecklistTemplate,
        isFalse,
      );
      controller.dispose();
    });

    test('atualiza documento do recebedor e persiste', () async {
      final repository = MemorySettingsRepository();
      final controller = SettingsController(
        getSettings: GetSettings(repository: repository),
        updateSetting: UpdateSetting(repository: repository),
      );
      await controller.ensureLoaded();

      await controller.setRequireReceiverDocument(true);

      expect(controller.snapshot.value.requireReceiverDocument, isTrue);
      expect(
        (await repository.load()).getOrNull()!.requireReceiverDocument,
        isTrue,
      );
      controller.dispose();
    });

    test('exibe erro quando a persistência falha', () async {
      final repository = _FailingUpdateRepository();
      final controller = SettingsController(
        getSettings: GetSettings(repository: repository),
        updateSetting: UpdateSetting(repository: repository),
      );
      await controller.ensureLoaded();

      await controller.setRequireChecklistTemplate(false);

      expect(controller.error.value, 'Falha ao salvar.');
      expect(controller.success.value, isNull);
      controller.dispose();
    });
  });
}
