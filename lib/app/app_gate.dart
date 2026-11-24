// Gate inicial para resolução da rota de entrada da aplicação.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

import 'app_controller.dart';

/// Widget exibido na rota raiz ('/') para resolver e despachar o usuário
/// para Onboarding, Lock ou Home de acordo com suas credenciais salvas.
final class AppGate extends IKortexPage<AppController> {
  const AppGate({super.key});

  @override
  Widget buildPage(BuildContext context, AppController controller) {
    controller.resolveInitialRoute().then((targetRoute) {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(targetRoute);
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
