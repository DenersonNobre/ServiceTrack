// Gate inicial para resolução da rota de entrada da aplicação.

import 'package:flutter/material.dart';

import '../modules/auth/features/app_entry/resolve_initial_route_use_case.dart';
import 'app_routes.dart';
import 'app_services.dart';

/// Widget exibido na rota raiz ('/') para resolver e despachar o usuário
/// para Onboarding, Lock ou Home de acordo com suas credenciais salvas.
class AppGate extends StatefulWidget {
  const AppGate({super.key, required this.services});

  final AppServices services;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  late final Future<AppEntryRoute> _future;
  bool _dispatched = false;

  @override
  void initState() {
    super.initState();
    _future = ResolveInitialRouteUseCase(
      repo: widget.services.credentialStore,
    ).execute()..then((target) {
        if (!mounted || _dispatched) return;
        _dispatched = true;
        _navigate(target);
      });
  }

  void _navigate(AppEntryRoute target) {
    final routeName = switch (target) {
      AppEntryRoute.onboarding => AppRoutes.onboarding,
      AppEntryRoute.lock => AppRoutes.lock,
      AppEntryRoute.home => AppRoutes.home,
    };
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppEntryRoute>(
      future: _future,
      builder: (context, snapshot) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
