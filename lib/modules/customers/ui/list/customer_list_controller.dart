// Controller da lista de clientes (UC-02.01/02.03 base).
//
// SRP: carregar e expor lista de clientes. Não renderiza UI.

import 'package:dnolib/core/patterns/result.dart';
import 'package:dnolib/core/patterns/validation_error.dart';
import 'package:kortex/kortex.dart';

import '../../domain/ports/customer_repository_port.dart';
import '../../domain/value_objects/customer.dart';

final class CustomerListController extends IKortexController {
  CustomerListController({required this.repository});
  final ICustomerRepositoryPort repository;

  final KortexSignal<bool> loading = KortexSignal<bool>(true);
  final KortexSignal<List<Customer>> customers = KortexSignal<List<Customer>>([]);
  final KortexSignal<String> query = KortexSignal<String>('');
  final KortexSignal<String?> error = KortexSignal<String?>(null);
  bool _loaded = false;

  /// Clientes filtrados pela busca em tempo real.
  List<Customer> get filteredCustomers {
    final q = query.value.trim().toLowerCase();
    final all = customers.value;
    if (q.isEmpty) return all;
    return all.where((c) {
      final name = c.name.value.toLowerCase();
      final doc = c.document?.digits ?? '';
      final phone = c.whatsapp.digits;
      return name.contains(q) || doc.contains(q) || phone.contains(q);
    }).toList();
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    final result = await repository.findAll();
    loading.value = false;
    switch (result) {
      case Success<List<Customer>, ValidationError>(:final value):
        customers.value = value;
      case Failure<List<Customer>, ValidationError>(:final value):
        error.value = value.message;
    }
  }

  @override
  void onDispose() {
    loading.dispose();
    customers.dispose();
    query.dispose();
    error.dispose();
  }
}
