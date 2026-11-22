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
  });

  final VoidCallback onProfile;
  final VoidCallback onCustomers;
  final VoidCallback onWorkOrders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ServiceTrack'),
        actions: [
          IconButton(
            key: const Key('home-work-orders'),
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Ordens de Serviço',
            onPressed: onWorkOrders,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          IconButton(
            key: const Key('home-customers'),
            icon: const Icon(Icons.people_outline),
            tooltip: 'Clientes',
            onPressed: onCustomers,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          IconButton(
            key: const Key('home-profile'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil comercial',
            onPressed: onProfile,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/home_hero_empty.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              const Text('Home - ServiceTrack'),
            ],
          ),
        ),
      ),
    );
  }
}
