// Controller da lista de locais de atendimento (UC-02.02).
//
// SRP: carregar e expor locais de um cliente. Não renderiza UI.

import 'package:kortex_lib/core/patterns/result.dart';
import 'package:kortex_lib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../domain/ports/service_location_repository_port.dart';
import '../../domain/value_objects/service_location.dart';

final class ServiceLocationListController extends IKortexController {
  ServiceLocationListController({required this.repository, required this.customerId});
  final IServiceLocationRepositoryPort repository;
  final String customerId;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<List<ServiceLocation>> locations = KortexSignal<List<ServiceLocation>>([]);
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final result = await repository.findByCustomerId(customerId);
    loading.value = false;
    switch (result) {
      case Success<List<ServiceLocation>, ValidationError>(:final value):
        locations.value = value;
      case Failure<List<ServiceLocation>, ValidationError>(:final value):
        error.value = value.message;
    }
  }

  Future<void> remove(String id) async {
    final result = await repository.delete(id);
    if (result case Failure<bool, ValidationError>(:final value)) {
      error.value = value.message;
      return;
    }
    await load();
  }

  @override
  void onDispose() {
    loading.dispose();
    locations.dispose();
    error.dispose();
  }
}
