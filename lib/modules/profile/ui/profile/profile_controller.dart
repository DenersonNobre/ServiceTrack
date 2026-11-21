// Controller do perfil comercial (UC-01.05).
//
// SRP: orquestrar carga/edição/salvamento do perfil comercial.
// Não conhece widgets, não faz picker, não acessa File diretamente.
//
// Pattern: IKortexController + Result.Fail tipado.

import 'dart:typed_data';

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../domain/ports/technician_profile_repository_port.dart';
import '../../domain/value_objects/technician_profile.dart';

/// Controller da tela de perfil comercial.
final class ProfileController extends IKortexController {
  /// Cria o controller.
  ProfileController({required this.repository});

  /// Repositório de perfil.
  final ITechnicianProfileRepositoryPort repository;

  /// Carregando.
  final KortexSignal<bool> loading = KortexSignal<bool>(true);

  /// Salvando.
  final KortexSignal<bool> saving = KortexSignal<bool>(false);

  /// Nome comercial.
  final KortexSignal<String> commercialName = KortexSignal<String>('');

  /// WhatsApp.
  final KortexSignal<String> whatsapp = KortexSignal<String>('');

  /// Caminho do logo gerenciado.
  final KortexSignal<String?> logoPath = KortexSignal<String?>(null);

  /// Erro de formulário.
  final KortexSignal<String?> error = KortexSignal<String?>(null);

  /// Mensagem de sucesso.
  final KortexSignal<String?> success = KortexSignal<String?>(null);

  bool _loaded = false;

  /// Carrega perfil uma vez.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    loading.value = true;
    final result = await repository.load();
    loading.value = false;
    switch (result) {
      case Success<TechnicianProfile?, ValidationError>(:final value):
        if (value != null) {
          commercialName.value = value.commercialName.value;
          whatsapp.value = value.whatsapp.digits;
          logoPath.value = value.logoPath;
        }
      case Failure<TechnicianProfile?, ValidationError>(:final value):
        error.value = value.message;
    }
  }

  /// Importa logo a partir de bytes já selecionados pela UI.
  Future<void> importLogo(Uint8List bytes) async {
    error.value = null;
    success.value = null;
    final result = await repository.importLogo(bytes);
    switch (result) {
      case Success<String, ValidationError>(:final value):
        logoPath.value = value;
      case Failure<String, ValidationError>(:final value):
        error.value = value.message;
    }
  }

  /// Remove logo.
  Future<void> removeLogo() async {
    error.value = null;
    success.value = null;
    final result = await repository.clearLogo();
    if (result.isSuccess) {
      logoPath.value = null;
    } else {
      error.value = result.getOrNullFailure()!.message;
    }
  }

  /// Salva perfil.
  Future<void> save() async {
    if (saving.value) return;
    saving.value = true;
    error.value = null;
    success.value = null;
    final profileResult = TechnicianProfile.tryCreate(
      commercialName: commercialName.value,
      whatsapp: whatsapp.value,
      logoPath: logoPath.value,
    );
    switch (profileResult) {
      case Failure<TechnicianProfile, ValidationError>(:final value):
        saving.value = false;
        error.value = value.message;
        return;
      case Success<TechnicianProfile, ValidationError>(:final value):
        final saved = await repository.save(value);
        saving.value = false;
        switch (saved) {
          case Success<bool, ValidationError>():
            success.value = 'Perfil atualizado com sucesso.';
          case Failure<bool, ValidationError>(:final value):
            error.value = value.message;
        }
    }
  }

  @override
  void onDispose() {
    loading.dispose();
    saving.dispose();
    commercialName.dispose();
    whatsapp.dispose();
    logoPath.dispose();
    error.dispose();
    success.dispose();
  }
}
