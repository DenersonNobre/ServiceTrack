// Controller de recuperação de PIN (UC-01.04).
//
// SRP: orquestrar fluxo de recuperação (senha mestre ou credencial do SO)
// e recadastro de novo PIN. Não renderiza, não persiste diretamente.
//
// Pattern: IKortexController + sinais de estado (A4: sem bypass UI).

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../domain/ports/auth_credential_repository_port.dart';
import '../../domain/value_objects/auth_credentials.dart';
import '../../features/recovery/pin_recovery_use_case.dart';

/// Etapas do fluxo de recuperação.
enum PinRecoveryStep {
  /// Escolha do método de recuperação.
  chooseMethod,

  /// Informar senha mestre.
  masterPassword,

  /// Informar novo PIN após autenticação.
  newPin,

  /// Recuperação concluída.
  done,
}

/// Controller da recuperação de PIN.
final class PinRecoveryController extends IKortexController {
  /// Cria o controller.
  PinRecoveryController({
    required this.useCase,
    required this.repository,
    this.onRecovered,
  });

  /// Caso de uso de recuperação.
  final PinRecoveryUseCase useCase;

  /// Repositório para markUnlocked.
  final IAuthCredentialRepositoryPort repository;

  /// Callback após recuperação bem-sucedida.
  final void Function()? onRecovered;

  /// Etapa atual.
  final KortexSignal<PinRecoveryStep> step =
      KortexSignal<PinRecoveryStep>(PinRecoveryStep.chooseMethod);

  /// Senha mestre digitada.
  final KortexSignal<String> masterPassword = KortexSignal<String>('');

  /// Novo PIN digitado.
  final KortexSignal<String> newPin = KortexSignal<String>('');

  /// Erro de senha mestre.
  final KortexSignal<String?> passwordError = KortexSignal<String?>(null);

  /// Erro de novo PIN.
  final KortexSignal<String?> pinError = KortexSignal<String?>(null);

  /// Carregamento.
  final KortexSignal<bool> loading = KortexSignal<bool>(false);

  /// Método autenticado internamente (A4): só setado após prova válida.
  bool _authenticatedByPassword = false;
  bool _pendingDeviceCredential = false;

  /// Seleciona recuperação por senha mestre.
  void chooseMasterPassword() {
    passwordError.value = null;
    masterPassword.value = '';
    step.value = PinRecoveryStep.masterPassword;
  }

  /// Seleciona recuperação por credencial do SO (auth acontece no submit).
  void chooseDeviceCredential() {
    pinError.value = null;
    newPin.value = '';
    _pendingDeviceCredential = true;
    _authenticatedByPassword = false;
    step.value = PinRecoveryStep.newPin;
  }

  /// Submete senha mestre e avança para novo PIN.
  Future<void> submitMasterPassword() async {
    if (loading.value) return;
    loading.value = true;
    passwordError.value = null;
    final verified = await repository.verifyPassword(masterPassword.value);
    loading.value = false;
    switch (verified) {
      case Success<bool, ValidationError>():
        _authenticatedByPassword = true;
        _pendingDeviceCredential = false;
        newPin.value = '';
        pinError.value = null;
        step.value = PinRecoveryStep.newPin;
      case Failure<bool, ValidationError>(:final value):
        passwordError.value = value.message;
    }
  }

  /// Adiciona dígito ao novo PIN.
  void appendDigit(String digit) {
    if (loading.value || step.value != PinRecoveryStep.newPin) return;
    if (newPin.value.length >= 6) return;
    pinError.value = null;
    newPin.value = '${newPin.value}$digit';
  }

  /// Remove último dígito do novo PIN.
  void backspace() {
    if (loading.value || step.value != PinRecoveryStep.newPin) return;
    if (newPin.value.isEmpty) return;
    pinError.value = null;
    newPin.value = newPin.value.substring(0, newPin.value.length - 1);
  }

  /// Confirma novo PIN e persiste reset (A4: exige auth prévia).
  Future<void> submitNewPin() async {
    if (loading.value) return;
    if (!_authenticatedByPassword && !_pendingDeviceCredential) {
      pinError.value = 'Recuperação não autorizada. Reinicie o fluxo.';
      step.value = PinRecoveryStep.chooseMethod;
      return;
    }
    final pinResult = SecurityPin.tryCreate(newPin.value);
    switch (pinResult) {
      case Failure<SecurityPin, ValidationError>(:final value):
        pinError.value = value.message;
        return;
      case Success<SecurityPin, ValidationError>(:final value):
        loading.value = true;
        pinError.value = null;
        final PinRecoveryResult result;
        if (_authenticatedByPassword) {
          result = await useCase.recoverWithPassword(
            passwordAttempt: masterPassword.value,
            newPin: value,
          );
        } else {
          result = await useCase.recoverWithDeviceCredential(newPin: value);
        }
        loading.value = false;
        switch (result) {
          case Success<bool, ValidationError>():
            _authenticatedByPassword = false;
            _pendingDeviceCredential = false;
            await repository.markUnlocked();
            step.value = PinRecoveryStep.done;
            onRecovered?.call();
          case Failure<bool, ValidationError>(:final value):
            pinError.value = value.message;
            if (value.code == 'ERR_RECUPERACAO_NAO_AUTORIZADA') {
              _pendingDeviceCredential = false;
              step.value = PinRecoveryStep.chooseMethod;
            }
        }
    }
  }

  /// Volta para escolha de método.
  void backToChoose() {
    _authenticatedByPassword = false;
    _pendingDeviceCredential = false;
    passwordError.value = null;
    pinError.value = null;
    masterPassword.value = '';
    newPin.value = '';
    step.value = PinRecoveryStep.chooseMethod;
  }
}
