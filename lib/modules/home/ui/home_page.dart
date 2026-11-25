// Tela inicial do ServiceTrack (navegação e resumo operacional).

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'home_controller.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_kpi_grid.dart';
import 'widgets/home_upcoming_section.dart';

/// Tela principal após desbloqueio do aplicativo.
final class HomePage extends IKortexPage<HomeController> {
  /// Cria a tela inicial com callbacks de navegação dos módulos.
  const HomePage({
    super.key,
    required this.onProfile,
    required this.onCustomers,
    required this.onWorkOrders,
    required this.onNewWorkOrder,
    required this.onChecklists,
    required this.onSettings,
    this.onSchedule,
  });

  final VoidCallback onProfile;
  final VoidCallback onCustomers;
  final VoidCallback onWorkOrders;
  final VoidCallback onNewWorkOrder;
  final VoidCallback onChecklists;
  final VoidCallback onSettings;
  final VoidCallback? onSchedule;

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        onCustomers();
      case 1:
        onWorkOrders();
      case 2:
        onChecklists();
      case 3:
        (onSchedule ?? onWorkOrders)();
    }
  }

  @override
  Widget buildPage(BuildContext context, HomeController controller) {
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        iconSize: 22,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        currentIndex: 0,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline, key: Key('bottom-nav-customers')),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.assignment_outlined,
              key: Key('bottom-nav-work-orders'),
            ),
            label: 'Ordens',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.checklist_outlined,
              key: Key('bottom-nav-checklists'),
            ),
            label: 'Modelos',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.calendar_month_outlined,
              key: Key('bottom-nav-schedule'),
            ),
            label: 'Agenda',
          ),
        ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  Text(
                    'Painel do dia',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  HomeKpiGrid(data: data, onOpenWorkOrders: onWorkOrders),
                  const SizedBox(height: 24),
                  HomeUpcomingSection(
                    upcoming: data.upcoming,
                    onOpenWorkOrders: onWorkOrders,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
