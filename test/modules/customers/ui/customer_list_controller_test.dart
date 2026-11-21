import 'package:flutter_test/flutter_test.dart';
import 'package:service_track/modules/customers/data/memory_customer_repository.dart';
import 'package:service_track/modules/customers/domain/value_objects/customer.dart';
import 'package:service_track/modules/customers/ui/list/customer_list_controller.dart';

void main() {
  test('UC-02.03 - filtra clientes por nome em tempo real', () async {
    final repo = MemoryCustomerRepository();
    await repo.save(Customer.tryCreate(id: '1', name: 'Ana', document: '', whatsapp: '11999998888', email: '', notes: '').getOrNull()!);
    await repo.save(Customer.tryCreate(id: '2', name: 'Bruno', document: '', whatsapp: '11999998888', email: '', notes: '').getOrNull()!);
    final controller = CustomerListController(repository: repo);
    await controller.load();

    controller.query.value = 'an';
    expect(controller.filteredCustomers.map((c) => c.name.value).toList(), ['Ana']);

    controller.query.value = '';
    expect(controller.filteredCustomers.length, 2);
    controller.dispose();
  });
}
