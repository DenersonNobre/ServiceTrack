// Controller da tela de Onboarding (UC-01.01, TASK-03).
//
// SRP: orquestra estado do formulário de onboarding, valida com os VOs
// e delega persistência à porta de credenciais. Não conhece widgets,
// Flutter storage ou rotas.
//
// Pattern: Controller kortex com sinais granulares + Result.

import 'package:kortex/kortex.dart';
import 'package:dnolib/core/patterns/validation_error.dart';

import '../../domain/ports/.index.dart';
import '../../domain/value_objects/.index.dart';

/// Estado e ações do formulário de onboarding inicial.
final class OnboardingController extends IKortexController {
  /// Cria o controller com a [repository] de credenciais.
  OnboardingController({required this.repository, this.onCompleted});

  /// Porta de persistência segura.
  final IAuthCredentialRepositoryPort repository;

  /// Callback opcional após cadastro concluído.
  final void Function()? onCompleted;

  /// Campos do formulário.
  final KortexSignal<String> name = KortexSignal('');
  final KortexSignal<String> email = KortexSignal('');
  final KortexSignal<String> password = KortexSignal('');
  final KortexSignal<String> pin = KortexSignal('');

  /// Erros por campo (null = sem erro).
  final KortexSignal<String?> nameError = KortexSignal(null);
  final KortexSignal<String?> emailError = KortexSignal(null);
  final KortexSignal<String?> passwordError = KortexSignal(null);
  final KortexSignal<String?> pinError = KortexSignal(null);

  /// Estado de submissão.
  final KortexSignal<bool> isSubmitting = KortexSignal(false);
  final KortexSignal<bool> submitted = KortexSignal(false);
  final KortexSignal<String?> submitError = KortexSignal(null);

  /// Valida e envia as credenciais; atualiza sinais de erro/sucesso.
  Future<void> submit() async {
    if (isSubmitting.value) {
      return;
    }
    submitError.value = null;
    submitted.value = false;

    final nameResult = TechnicianName.tryCreate(name.value);
    final emailResult = ContactEmail.tryCreate(email.value);
    final passwordResult = MasterPassword.tryCreate(password.value);
    final pinResult = SecurityPin.tryCreate(pin.value);

    nameError.value = _messageOf(nameResult.getOrNullFailure());
    emailError.value = _messageOf(emailResult.getOrNullFailure());
    passwordError.value = _messageOf(passwordResult.getOrNullFailure());
    pinError.value = _messageOf(pinResult.getOrNullFailure());

    final hasError = nameResult.isFailure ||
        emailResult.isFailure ||
        passwordResult.isFailure ||
        pinResult.isFailure;
    if (hasError) {
      return;
    }

    isSubmitting.value = true;
    try {
      final result = await repository.saveCredentials(
        password: passwordResult.getOrThrow(),
        pin: pinResult.getOrThrow(),
      );
      result.fold(
        onSuccess: (_) {
          submitted.value = true;
          onCompleted?.call();
        },
        onFailure: (error) => submitError.value = error.message,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  String? _messageOf(ValidationError? error) => error?.message;

  @override
  void onDispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    pin.dispose();
    nameError.dispose();
    emailError.dispose();
    passwordError.dispose();
    pinError.dispose();
    isSubmitting.dispose();
    submitted.dispose();
    submitError.dispose();
  }
}
