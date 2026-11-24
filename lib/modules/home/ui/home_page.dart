// Tela inicial do ServiceTrack (dashboard operacional + navegação).

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'home_dashboard_controller.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_kpi_grid.dart';
import 'widgets/home_upcoming_section.dart';

/// Tela principal após desbloqueio do aplicativo.
final class HomePage extends IKortexPage<HomeDashboardController> {
  /// Cria a tela inicial com callbacks de navegação dos módulos.
  const HomePage({
    super.key,
    required this.onProfile,
    required this.onCustomers,
    required this.onWorkOrders,
    required this.onNewWorkOrder,
    required this.onChecklists,
    required this.onSettings,
  });

  final VoidCallback onProfile;
  final VoidCallback onCustomers;
  final VoidCallback onWorkOrders;
  final VoidCallback onNewWorkOrder;
  final VoidCallback onChecklists;
  final VoidCallback onSettings;

  @override
  Widget buildPage(BuildContext context, HomeDashboardController controller) {
    controller.ensureLoaded();
    return Scaffold(
      appBar: AppBar(title: const Text('ServiceTrack')),
      drawer: HomeDrawer(
        onProfile: onProfile,
        onCustomers: onCustomers,
        onWorkOrders: onWorkOrders,
        onChecklists: onChecklists,
        onSettings: onSettings,
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('home-new-work-order'),
        onPressed: onNewWorkOrder,
        icon: const Icon(Icons.add),
        label: const Text('Nova OS'),
      ),
      body: SafeArea(
        child: KortexWatch(
          builder: (context, _) {
            debugPrint(
              '[HomePage] KortexWatch builder running, loading=${controller.loading.value}, error=${controller.error.value}',
            );
            if (controller.loading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final err = controller.error.value;
            if (err != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(err, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => controller.load(),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final data = controller.data.value;
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Text(
                    'Painel do dia',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  HomeKpiGrid(data: data, onOpenWorkOrders: onWorkOrders),
                  const SizedBox(height: 24),
                  HomeUpcomingSection(
                    upcoming: data.upcoming,
                    onOpenWorkOrders: onWorkOrders,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
