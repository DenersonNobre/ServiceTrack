// Tela inicial do ServiceTrack (shell de navegação entre módulos).

import 'package:flutter/material.dart';

/// Tela principal após desbloqueio do aplicativo.
final class HomePage extends StatelessWidget {
  /// Cria a tela inicial com callbacks de navegação dos módulos.
  const HomePage({
    super.key,
    required this.onProfile,
    required this.onCustomers,
    required this.onWorkOrders,
    required this.onChecklists,
    required this.onSettings,
  });

  /// Navega para o perfil comercial.
  final VoidCallback onProfile;

  /// Navega para a lista de clientes.
  final VoidCallback onCustomers;

  /// Navega para ordens de serviço.
  final VoidCallback onWorkOrders;

  /// Navega para modelos de checklist.
  final VoidCallback onChecklists;

  /// Navega para configurações.
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ServiceTrack')),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: scheme.primaryContainer),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 40,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ServiceTrack',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestão de visitas técnicas',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
              _DrawerItem(
                key: const Key('drawer-home'),
                icon: Icons.home_outlined,
                label: 'Início',
                onTap: () => Navigator.of(context).pop(),
              ),
              const Divider(height: 1),
              _DrawerItem(
                key: const Key('drawer-customers'),
                icon: Icons.people_outline,
                label: 'Clientes',
                onTap: () => _navigate(context, onCustomers),
              ),
              _DrawerItem(
                key: const Key('drawer-work-orders'),
                icon: Icons.assignment_outlined,
                label: 'Ordens de Serviço',
                onTap: () => _navigate(context, onWorkOrders),
              ),
              _DrawerItem(
                key: const Key('drawer-checklists'),
                icon: Icons.checklist_outlined,
                label: 'Modelos de Checklist',
                onTap: () => _navigate(context, onChecklists),
              ),
              const Divider(height: 1),
              _DrawerItem(
                key: const Key('drawer-profile'),
                icon: Icons.person_outline,
                label: 'Perfil comercial',
                onTap: () => _navigate(context, onProfile),
              ),
              _DrawerItem(
                key: const Key('drawer-settings'),
                icon: Icons.settings_outlined,
                label: 'Configurações',
                onTap: () => _navigate(context, onSettings),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo ao ServiceTrack',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gerencie clientes, ordens de serviço, checklists e evidências '
                    'diretamente no seu aparelho.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Acesso rápido', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _HomeActionCard(
            key: const Key('home-customers'),
            icon: Icons.people_outline,
            title: 'Clientes',
            subtitle: 'Cadastre e consulte sua carteira',
            onTap: onCustomers,
          ),
          _HomeActionCard(
            key: const Key('home-work-orders'),
            icon: Icons.assignment_outlined,
            title: 'Ordens de Serviço',
            subtitle: 'Crie, acompanhe e conclua OS',
            onTap: onWorkOrders,
          ),
          _HomeActionCard(
            key: const Key('home-checklists'),
            icon: Icons.checklist_outlined,
            title: 'Modelos de Checklist',
            subtitle: 'Cadastre modelos reutilizáveis',
            onTap: onChecklists,
          ),
          _HomeActionCard(
            key: const Key('home-profile'),
            icon: Icons.person_outline,
            title: 'Perfil comercial',
            subtitle: 'Dados do técnico para laudos',
            onTap: onProfile,
          ),
          _HomeActionCard(
            key: const Key('home-settings'),
            icon: Icons.settings_outlined,
            title: 'Configurações',
            subtitle: 'Políticas e preferências locais',
            onTap: onSettings,
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }
}

final class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
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

final class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
