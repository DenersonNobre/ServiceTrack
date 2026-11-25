import 'package:flutter/material.dart';

/// Drawer de navegação principal da Home.
final class HomeDrawer extends StatelessWidget {
  /// Cria o drawer da home com callbacks para cada destino.
  const HomeDrawer({
    super.key,
    required this.onProfile,
    required this.onCustomers,
    required this.onWorkOrders,
    required this.onChecklists,
    required this.onSettings,
    required this.onReportHistory,
  });

  final VoidCallback onProfile;
  final VoidCallback onCustomers;
  final VoidCallback onWorkOrders;
  final VoidCallback onChecklists;
  final VoidCallback onSettings;
  final VoidCallback onReportHistory;

  void _navigate(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primaryContainer),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.build_circle_outlined,
                      size: 36,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ServiceTrack',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gestão de visitas técnicas',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ),
            HomeDrawerItem(
              key: const Key('drawer-home'),
              icon: Icons.home_outlined,
              label: 'Início',
              onTap: () => Navigator.of(context).pop(),
            ),
            const Divider(height: 1),
            HomeDrawerItem(
              key: const Key('drawer-customers'),
              icon: Icons.people_outline,
              label: 'Clientes',
              onTap: () => _navigate(context, onCustomers),
            ),
            HomeDrawerItem(
              key: const Key('drawer-work-orders'),
              icon: Icons.assignment_outlined,
              label: 'Ordens de Serviço',
              onTap: () => _navigate(context, onWorkOrders),
            ),
            HomeDrawerItem(
              key: const Key('drawer-checklists'),
              icon: Icons.checklist_outlined,
              label: 'Modelos de Checklist',
              onTap: () => _navigate(context, onChecklists),
            ),
            HomeDrawerItem(
              key: const Key('drawer-report-history'),
              icon: Icons.picture_as_pdf_outlined,
              label: 'Histórico de Laudos',
              onTap: () => _navigate(context, onReportHistory),
            ),
            const Divider(height: 1),
            HomeDrawerItem(
              key: const Key('drawer-profile'),
              icon: Icons.person_outline,
              label: 'Perfil comercial',
              onTap: () => _navigate(context, onProfile),
            ),
            HomeDrawerItem(
              key: const Key('drawer-settings'),
              icon: Icons.settings_outlined,
              label: 'Configurações',
              onTap: () => _navigate(context, onSettings),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item clicável do menu lateral com alvo de toque acessível.
final class HomeDrawerItem extends StatelessWidget {
  /// Cria um item do drawer com ícone e rótulo.
  const HomeDrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      minTileHeight: 48,
      onTap: onTap,
    );
  }
}
