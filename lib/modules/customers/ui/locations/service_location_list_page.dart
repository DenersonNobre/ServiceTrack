// Lista de locais de atendimento (UC-02.02).
//
// SRP: renderizar locais e delegar ações ao controller.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/.index.dart';
import '../../../../core/ui/.index.dart';
import '../../domain/value_objects/service_location.dart';
import 'service_location_list_controller.dart';

final class ServiceLocationListPage extends IKortexPage<ServiceLocationListController> {
  const ServiceLocationListPage({super.key, required this.customerName, this.onAdd, this.onEdit});
  final String customerName;
  final VoidCallback? onAdd;
  final void Function(ServiceLocation location)? onEdit;

  @override
  Widget buildPage(BuildContext context, ServiceLocationListController controller) {
    controller.ensureLoaded();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: Text('Locais - $customerName')),
      floatingActionButton: FloatingActionButton(
        key: const Key('location-add'),
        backgroundColor: AppColors.primaryAction,
        foregroundColor: Colors.white,
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryAction));
            }
            if (controller.error.value != null) {
              return Center(child: Text(controller.error.value!, style: const TextStyle(color: AppColors.error)));
            }
            final items = controller.locations.value;
            if (items.isEmpty) {
              return const AppEmptyState(
                icon: Icons.place_outlined,
                imageAsset: 'assets/images/empty_locations.png',
                title: 'Nenhum local cadastrado.',
                message: 'Adicione um endereço de atendimento para este cliente.',
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final l = items[i];
                final subtitle = [l.street, l.number, l.neighborhood, l.city].where((e) => e.isNotEmpty).join(', ');
                return DismissibleTile(
                  itemKey: ValueKey<String>(l.id),
                  confirmTitle: 'Excluir local de atendimento?',
                  confirmMessage: 'Deseja realmente remover o local "${l.label.value}"?',
                  onDismissed: () {
                    controller.remove(l.id);
                    AppFeedback.showSuccess(context, 'Local de atendimento removido com sucesso');
                  },
                  child: ListTile(
                    key: Key('location-${l.id}'),
                    title: Text(l.label.value),
                    subtitle: Text(subtitle),
                    onTap: () => onEdit?.call(l),
                    minTileHeight: 56,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
