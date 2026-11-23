// Controller do formulário de cliente (UC-02.01).
//
// SRP: orquestrar criação/edição de cliente. Não renderiza UI.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ports/customer_repository_port.dart';
import '../../domain/value_objects/customer.dart';

final class CustomerFormController extends IKortexController {
  CustomerFormController({required this.repository, this.customerId});
  final ICustomerRepositoryPort repository;
  final String? customerId;

  final KortexSignal<bool> loading = KortexSignal<bool>(false);
  final KortexSignal<bool> saving = KortexSignal<bool>(false);
  final KortexSignal<String> name = KortexSignal<String>('');
  final KortexSignal<String> document = KortexSignal<String>('');
  final KortexSignal<String> whatsapp = KortexSignal<String>('');
  final KortexSignal<String> email = KortexSignal<String>('');
  final KortexSignal<String> notes = KortexSignal<String>('');
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  final KortexSignal<bool> saved = KortexSignal<bool>(false);

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final id = customerId;
    if (id == null) return;
    loading.value = true;
    final result = await repository.findById(id);
    loading.value = false;
    switch (result) {
      case Success<Customer?, ValidationError>(:final value):
        if (value == null) {
          error.value = 'Cliente não encontrado.';
          return;
        }
        name.value = value.name.value;
        document.value = value.document?.digits ?? '';
        whatsapp.value = value.whatsapp.digits;
        email.value = value.email?.value ?? '';
        notes.value = value.notes;
      case Failure<Customer?, ValidationError>(:final value):
        error.value = value.message;
    }
  }

  Future<void> save() async {
    if (saving.value) return;
    saving.value = true;
    error.value = null;
    final id = customerId ?? const Uuid().v4();
    final customerR = Customer.tryCreate(
      id: id,
      name: name.value,
      document: document.value,
      whatsapp: whatsapp.value,
      email: email.value,
      notes: notes.value,
    );
    switch (customerR) {
      case Failure<Customer, ValidationError>(:final value):
        saving.value = false;
        error.value = value.message;
        return;
      case Success<Customer, ValidationError>(:final value):
        final result = await repository.save(value);
        saving.value = false;
        switch (result) {
          case Success<Customer, ValidationError>():
            saved.value = true;
          case Failure<Customer, ValidationError>(:final value):
            error.value = value.message;
        }
    }
  }

  @override
  void onDispose() {
    loading.dispose();
    saving.dispose();
    name.dispose();
    document.dispose();
    whatsapp.dispose();
    email.dispose();
    notes.dispose();
    error.dispose();
    saved.dispose();
  }
}
