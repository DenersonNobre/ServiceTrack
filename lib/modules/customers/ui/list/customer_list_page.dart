// Lista de clientes (UC-02.01).
//
// SRP: renderizar lista e delegar ações ao controller.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/value_objects/customer.dart';
import 'customer_list_controller.dart';

final class CustomerListPage extends IKortexPage<CustomerListController> {
  const CustomerListPage({super.key, this.onAdd, this.onEdit, this.onLocations, this.onDetail});
  final VoidCallback? onAdd;
  final void Function(Customer customer)? onEdit;
  final void Function(Customer customer)? onLocations;
  final void Function(Customer customer)? onDetail;

  @override
  Widget buildPage(BuildContext context, CustomerListController controller) {
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Clientes')),
      floatingActionButton: FloatingActionButton(
        key: const Key('customer-add'),
        backgroundColor: AppColors.primaryAction,
        foregroundColor: Colors.white,
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                key: const Key('customer-search'),
                onChanged: (v) => controller.query.value = v,
                decoration: const InputDecoration(
                  hintText: 'Buscar cliente...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  constraints: BoxConstraints(minHeight: 48),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: KortexWatch(
                builder: (context, _) {
                  if (controller.loading.value) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryAction));
                  }
                  if (controller.error.value != null) {
                    return Center(child: Text(controller.error.value!));
                  }
                  final items = controller.filteredCustomers;
                  if (controller.customers.value.isEmpty) {
                    return const Center(child: Text('Nenhum cliente cadastrado.'));
                  }
                  if (items.isEmpty) {
                    return const Center(child: Text('Nenhum cliente encontrado.'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = items[i];
                      return ListTile(
                        key: Key('customer-${c.id}'),
                        title: Text(c.name.value),
                        subtitle: Text(c.whatsapp.digits),
                        onTap: () => (onDetail ?? onEdit)?.call(c),
                        minTileHeight: 56,
                        trailing: IconButton(
                          key: Key('customer-locations-${c.id}'),
                          icon: const Icon(Icons.place_outlined),
                          tooltip: 'Locais',
                          onPressed: () => onLocations?.call(c),
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
