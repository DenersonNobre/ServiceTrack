// Controller da tela de bloqueio/desbloqueio (UC-01.02).
//
// SRP: orquestrar biometria e PIN manual, expondo estado reativo para a UI.
// Não conhece widgets nem local_auth; usa portas/use cases.
//
// Pattern: IKortexController + Signals, fail-closed.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../domain/ports/.index.dart';
import '../../features/biometric_unlock/.index.dart';

/// Estado reativo da tela de bloqueio.
final class LockController extends IKortexController {
  /// Cria o controller.
  LockController({
    required this.biometricUnlock,
    required this.repository,
    this.onUnlocked,
    this.onForgotPin,
  });

  /// Caso de uso de biometria.
  final BiometricUnlockUseCase biometricUnlock;

  /// Repositório de credenciais/configurações.
  final IAuthCredentialRepositoryPort repository;

  /// Callback invocado quando o acesso é liberado.
  final void Function()? onUnlocked;

  /// Callback para fluxo "Esqueci meu PIN" (UC-01.04).
  final void Function()? onForgotPin;

  /// Indica que a avaliação biométrica inicial está em andamento.
  final KortexSignal<bool> checkingBiometric = KortexSignal<bool>(true);

  /// Indica que o formulário de PIN deve ser exibido.
  final KortexSignal<bool> showPin = KortexSignal<bool>(false);

  /// Mensagem de erro do PIN.
  final KortexSignal<String?> pinError = KortexSignal<String?>(null);

  /// Indica submissão de PIN em andamento.
  final KortexSignal<bool> submittingPin = KortexSignal<bool>(false);

  /// Valor atual do PIN digitado.
  final KortexSignal<String> pin = KortexSignal<String>('');

  bool _unlocked = false;
  bool _initialized = false;

  /// Adiciona um dígito ao PIN (UC-01.03).
  void appendDigit(String digit) {
    if (_unlocked || submittingPin.value) return;
    if (pin.value.length >= 6) return;
    pinError.value = null;
    pin.value = '${pin.value}$digit';
  }

  /// Remove o último dígito do PIN (UC-01.03).
  void backspace() {
    if (_unlocked || submittingPin.value) return;
    if (pin.value.isEmpty) return;
    pinError.value = null;
    pin.value = pin.value.substring(0, pin.value.length - 1);
  }

  /// Dispara inicialização única.
  void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    // ignore: discarded_futures
    init();
  }

  /// Inicializa: tenta biometria se habilitada (UC-01.02).
  Future<void> init() async {
    checkingBiometric.value = true;
    try {
      final enabledResult = await repository.isBiometricsEnabled();
      final enabled = switch (enabledResult) {
        Success<bool, ValidationError>(:final value) => value,
        Failure<bool, ValidationError>() => false,
      };
      final decision = await biometricUnlock.execute(biometricsEnabled: enabled);
      switch (decision) {
        case UnlockDecision.grantHome:
          await _grantAccess();
        case UnlockDecision.requirePin:
        case UnlockDecision.stayOnPin:
          showPin.value = true;
      }
    } catch (_) {
      showPin.value = true;
    } finally {
      checkingBiometric.value = false;
    }
  }

  /// Submete PIN manual.
  Future<void> submitPin() async {
    if (submittingPin.value || _unlocked) return;
    pinError.value = null;
    submittingPin.value = true;
    try {
      final result = await repository.verifyPin(pin.value);
      switch (result) {
        case Success<bool, ValidationError>():
          await _grantAccess();
        case Failure<bool, ValidationError>(value: final error):
          pinError.value = error.message;
      }
    } finally {
      submittingPin.value = false;
    }
  }

  /// Aciona fluxo de recuperação de PIN (UC-01.04).
  void forgotPin() {
    onForgotPin?.call();
  }

  Future<void> _grantAccess() async {
    if (_unlocked) return;
    _unlocked = true;
    await repository.markUnlocked();
    onUnlocked?.call();
  }

  @override
  void onDispose() {
    checkingBiometric.dispose();
    showPin.dispose();
    pinError.dispose();
    submittingPin.dispose();
    pin.dispose();
  }
}
