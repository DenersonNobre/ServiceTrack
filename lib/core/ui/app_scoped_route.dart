// Helper de rota escopada com KortexScope e auto-dispose (ServiceTrack Core UI).
//
// SRP: eliminar boilerplate de MaterialPageRoute + KortexScope + KortexProvider
// nos arquivos *_routes.dart dos módulos, sem acoplar navegação ao pacote kortex.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

/// Cria uma [MaterialPageRoute] embrulhada em [KortexScope] com descarte
/// automático do controller [T] ao remover a rota da pilha.
Route<R> appScopedRoute<T extends IKortexDisposable, R>({
  required KortexCreate<T> create,
  required Widget Function(BuildContext context, T controller) builder,
  RouteSettings? settings,
}) {
  return MaterialPageRoute<R>(
    settings: settings,
    builder: (_) => KortexScope(
      providers: [
        KortexProvider<T>(
          create: create,
          dispose: (controller) => controller.dispose(),
        ),
      ],
      child: Builder(
        builder: (scopeContext) =>
            builder(scopeContext, scopeContext.readKortex<T>()),
      ),
    ),
  );
}
