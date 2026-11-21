// Controller de detalhes do cliente (UC-02.04).
//
// SRP: carregar e expor detalhes do cliente. Não renderiza UI.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../domain/ports/customer_repository_port.dart';
import '../../domain/value_objects/customer.dart';

final class CustomerDetailController extends IKortexController {
  CustomerDetailController({required this.repository, required this.customerId});
  final ICustomerRepositoryPort repository;
  final String customerId;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<Customer?> customer = KortexSignal<Customer?>(null);
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
    final result = await repository.findById(customerId);
    loading.value = false;
    switch (result) {
      case Success<Customer?, ValidationError>(:final value):
        if (value == null) {
          error.value = 'Cliente não encontrado.';
          return;
        }
        customer.value = value;
      case Failure<Customer?, ValidationError>(:final value):
        error.value = value.message;
    }
  }

  @override
  void onDispose() {
    loading.dispose();
    customer.dispose();
    error.dispose();
  }
}
