// Controller transversal do aplicativo ServiceTrack.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import '../modules/auth/features/app_entry/resolve_initial_route_use_case.dart';
import 'app_services.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

/// Controlador raiz da aplicação responsável por agregar serviços,
/// gerenciar a chave de navegação, mapeamento de rotas e preferências transversais (tema),
/// além de monitorar o ciclo de vida da aplicação para bloqueio automático por inatividade.
class AppController extends IKortexController with WidgetsBindingObserver {
  /// Cria o controlador injetando serviços e chave de navegação opcional.
  AppController({
    required this.services,
    GlobalKey<NavigatorState>? navigatorKey,
    ThemeMode initialThemeMode = ThemeMode.light,
    this.lockTimeout = const Duration(minutes: 5),
    this.clock = DateTime.now,
    this.onRelock,
    this.enableLifecycleObserver = true,
  })  : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        themeMode = KortexSignal<ThemeMode>(initialThemeMode) {
    pages = AppPages(
      services: services,
      navigatorKey: this.navigatorKey,
    );

    if (enableLifecycleObserver) {
      ambiguate(WidgetsBinding.instance)?.addObserver(this);
    }
  }

  /// Construtor de conveniência que deriva serviços de banco SQLite quando omitidos.
  factory AppController.fromDatabase({
    SqliteProvider? database,
    AppServices? services,
    GlobalKey<NavigatorState>? navigatorKey,
    ThemeMode initialThemeMode = ThemeMode.light,
    Duration lockTimeout = const Duration(minutes: 5),
    DateTime Function() clock = DateTime.now,
    void Function()? onRelock,
    bool enableLifecycleObserver = true,
  }) {
    final resolvedServices =
        services ?? AppServices.fromDatabase(database: database);
    return AppController(
      services: resolvedServices,
      navigatorKey: navigatorKey,
      initialThemeMode: initialThemeMode,
      lockTimeout: lockTimeout,
      clock: clock,
      onRelock: onRelock,
      enableLifecycleObserver: enableLifecycleObserver,
    );
  }

  /// Serviços transversais agregados da aplicação.
  final AppServices services;

  /// Chave de navegação global.
  final GlobalKey<NavigatorState> navigatorKey;

  /// Roteador declarativo de páginas e módulos.
  late final AppPages pages;

  /// Modo de tema reativo (Light por padrão).
  final KortexSignal<ThemeMode> themeMode;

  /// Tempo limite de inatividade em background para auto-bloqueio.
  final Duration lockTimeout;

  /// Fonte de tempo para testabilidade.
  final DateTime Function() clock;

  /// Callback customizado opcional disparado quando o auto-bloqueio ocorre.
  final void Function()? onRelock;

  /// Se o observer do ciclo de vida deve ser registrado no WidgetsBinding.
  final bool enableLifecycleObserver;
  DateTime? _pausedAt;

  /// Resolve a rota inicial com base nas credenciais e sessão lembrada.
  Future<String> resolveInitialRoute() async {
    final route = await ResolveInitialRouteUseCase(
      repo: services.credentialStore,
    ).execute();

    return switch (route) {
      AppEntryRoute.onboarding => AppRoutes.onboarding,
      AppEntryRoute.lock => AppRoutes.lock,
      AppEntryRoute.home => AppRoutes.home,
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = clock();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final elapsed = clock().difference(_pausedAt!);
        _pausedAt = null;
        if (elapsed >= lockTimeout) {
          triggerRelock();
        }
      }
    }
  }

  /// Força o bloqueio e redirecionamento para a tela de lock.
  void triggerRelock() {
    if (onRelock != null) {
      onRelock!();
      return;
    }

    final navState = navigatorKey.currentState;
    if (navState != null) {
      navState.pushReplacementNamed(AppRoutes.lock);
    }
  }

  /// Libera recursos e listeners reativos.
  @override
  void dispose() {
    if (enableLifecycleObserver) {
      ambiguate(WidgetsBinding.instance)?.removeObserver(this);
    }
    themeMode.dispose();
    super.dispose();
  }
}

/// Helper para compatibilidade de anotação nula do WidgetsBinding.instance em diferentes SDKs.
@visibleForTesting
T? ambiguate<T>(T? value) => value;
