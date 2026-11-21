// Página de detalhes do cliente (UC-02.04).
//
// SRP: renderizar detalhes do cliente e histórico de OS. Não contém regra de negócio.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/value_objects/customer.dart';
import 'customer_detail_controller.dart';

final class CustomerDetailPage extends IKortexPage<CustomerDetailController> {
  const CustomerDetailPage({super.key, this.onEdit, this.onLocations});

  final VoidCallback? onEdit;
  final VoidCallback? onLocations;

  @override
  Widget buildPage(BuildContext context, CustomerDetailController controller) {
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Detalhes do Cliente'),
        actions: [
          if (onEdit != null)
            IconButton(
              key: const Key('customer-detail-edit'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: onEdit,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          if (onLocations != null)
            IconButton(
              key: const Key('customer-detail-locations'),
              icon: const Icon(Icons.place_outlined),
              tooltip: 'Locais',
              onPressed: onLocations,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
        ],
      ),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryAction));
            }
            if (controller.error.value != null) {
              return Center(child: Text(controller.error.value!));
            }
            final c = controller.customer.value;
            if (c == null) return const Center(child: Text('Cliente não encontrado.'));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoCard(customer: c),
                const SizedBox(height: 16),
                Text('Histórico de Ordens de Serviço', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Card(
                  color: AppColors.surfaceCard,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhuma OS emitida.'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value.isEmpty ? '-' : value)),
          ]),
        );
    return Card(
      color: AppColors.surfaceCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(customer.name.value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          row('Documento', customer.document?.digits ?? ''),
          row('WhatsApp', customer.whatsapp.digits),
          row('E-mail', customer.email?.value ?? ''),
          row('Observações', customer.notes),
        ]),
      ),
    );
  }
}
