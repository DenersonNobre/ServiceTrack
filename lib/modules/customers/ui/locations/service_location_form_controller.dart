// Controller do formulário de local de atendimento (UC-02.02).
//
// SRP: orquestrar criação/edição de local. Não renderiza UI.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ports/service_location_repository_port.dart';
import '../../domain/value_objects/service_location.dart';

final class ServiceLocationFormController extends IKortexController {
  ServiceLocationFormController({required this.repository, required this.customerId, this.locationId, this.initial});
  final IServiceLocationRepositoryPort repository;
  final String customerId;
  final String? locationId;
  final ServiceLocation? initial;

  final KortexSignal<bool> saving = KortexSignal<bool>(false);
  final KortexSignal<String> label = KortexSignal<String>('');
  final KortexSignal<String> street = KortexSignal<String>('');
  final KortexSignal<String> number = KortexSignal<String>('');
  final KortexSignal<String> neighborhood = KortexSignal<String>('');
  final KortexSignal<String> city = KortexSignal<String>('');
  final KortexSignal<String> state = KortexSignal<String>('');
  final KortexSignal<String> cep = KortexSignal<String>('');
  final KortexSignal<String> reference = KortexSignal<String>('');
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  final KortexSignal<bool> saved = KortexSignal<bool>(false);
  bool _loaded = false;

  void ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    final l = initial;
    if (l == null) return;
    label.value = l.label.value;
    street.value = l.street;
    number.value = l.number;
    neighborhood.value = l.neighborhood;
    city.value = l.city;
    state.value = l.state;
    cep.value = l.cep?.digits ?? '';
    reference.value = l.reference;
  }

  Future<void> save() async {
    if (saving.value) return;
    saving.value = true;
    error.value = null;
    final id = locationId ?? const Uuid().v4();
    final result = ServiceLocation.tryCreate(
      id: id,
      customerId: customerId,
      label: label.value,
      street: street.value,
      number: number.value,
      neighborhood: neighborhood.value,
      city: city.value,
      state: state.value,
      cep: cep.value,
      reference: reference.value,
    );
    switch (result) {
      case Failure<ServiceLocation, ValidationError>(:final value):
        saving.value = false;
        error.value = value.message;
        return;
      case Success<ServiceLocation, ValidationError>(:final value):
        final savedR = await repository.save(value);
        saving.value = false;
        switch (savedR) {
          case Success<ServiceLocation, ValidationError>():
            saved.value = true;
          case Failure<ServiceLocation, ValidationError>(:final value):
            error.value = value.message;
        }
    }
  }

  @override
  void onDispose() {
    saving.dispose();
    label.dispose();
    street.dispose();
    number.dispose();
    neighborhood.dispose();
    city.dispose();
    state.dispose();
    cep.dispose();
    reference.dispose();
    error.dispose();
    saved.dispose();
  }
}
