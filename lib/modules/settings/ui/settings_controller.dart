import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex/kortex.dart';

import '../domain/.index.dart';
import '../features/.index.dart';

/// Controller Kortex da tela de configurações locais.
///
/// SRP: carregar snapshot e persistir políticas via use cases.
/// Não renderiza UI nem acessa SQLite diretamente.
final class SettingsController extends IKortexController {
  SettingsController({required this.getSettings, required this.updateSetting});

  final GetSettings getSettings;
  final UpdateSetting updateSetting;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<bool> saving = KortexSignal<bool>(false);
  final KortexSignal<SettingsSnapshot> snapshot =
      KortexSignal<SettingsSnapshot>(SettingsSnapshot.defaults());
  final KortexSignal<String?> loadError = KortexSignal<String?>(null);
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  final KortexSignal<String?> success = KortexSignal<String?>(null);

  bool _loaded = false;

  /// Carrega uma vez ao abrir a tela.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    await load();
  }

  /// Recarrega o snapshot vigente.
  Future<void> load() async {
    loading.value = true;
    loadError.value = null;
    final result = await getSettings.execute();
    loading.value = false;
    switch (result) {
      case Success(:final value):
        snapshot.value = value;
      case Failure(:final value):
        loadError.value = value.message;
    }
  }

  /// Atualiza a política de checklist obrigatório.
  Future<void> setRequireChecklistTemplate(bool value) =>
      _update(SettingKey.requireChecklistTemplate, value);

  /// Atualiza a política de documento do recebedor.
  Future<void> setRequireReceiverDocument(bool value) =>
      _update(SettingKey.requireReceiverDocument, value);

  /// Restaura os defaults do catálogo (recuperação de settings corrompido).
  Future<void> restoreDefaults() async {
    if (saving.value) return;
    saving.value = true;
    error.value = null;
    success.value = null;
    for (final key in SettingKey.values) {
      final result = await updateSetting.execute(
        key: key.storageKey,
        value: key.defaultValue,
      );
      if (result case Failure(:final value)) {
        saving.value = false;
        error.value = value.message;
        return;
      }
    }
    saving.value = false;
    success.value = 'Configurações restauradas.';
    await load();
  }

  Future<void> _update(SettingKey key, bool value) async {
    if (saving.value) return;
    saving.value = true;
    error.value = null;
    success.value = null;
    final result = await updateSetting.execute(
      key: key.storageKey,
      value: value,
    );
    saving.value = false;
    switch (result) {
      case Success(:final value):
        snapshot.value = value;
        success.value = 'Configuração salva.';
      case Failure(:final value):
        error.value = value.message;
    }
  }

  @override
  void onDispose() {
    loading.dispose();
    saving.dispose();
    snapshot.dispose();
    loadError.dispose();
    error.dispose();
    success.dispose();
  }
}
