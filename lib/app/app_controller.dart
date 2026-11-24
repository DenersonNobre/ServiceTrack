// Controller transversal do aplicativo ServiceTrack.

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import 'app_pages.dart';
import 'app_services.dart';

/// Controlador raiz da aplicação responsável por agregar serviços,
/// gerenciar a chave de navegação, mapeamento de rotas e preferências transversais (tema).
class AppController {
  /// Cria o controlador injetando serviços e chave de navegação opcional.
  AppController({
    required this.services,
    GlobalKey<NavigatorState>? navigatorKey,
    ThemeMode initialThemeMode = ThemeMode.light,
  })  : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        themeMode = KortexSignal<ThemeMode>(initialThemeMode) {
    pages = AppPages(
      services: services,
      navigatorKey: this.navigatorKey,
    );
  }

  /// Construtor de conveniência que deriva serviços de banco SQLite quando omitidos.
  factory AppController.fromDatabase({
    SqliteProvider? database,
    AppServices? services,
    GlobalKey<NavigatorState>? navigatorKey,
    ThemeMode initialThemeMode = ThemeMode.light,
  }) {
    final resolvedServices =
        services ?? AppServices.fromDatabase(database: database);
    return AppController(
      services: resolvedServices,
      navigatorKey: navigatorKey,
      initialThemeMode: initialThemeMode,
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

  /// Libera recursos e listeners reativos.
  void dispose() {
    themeMode.dispose();
  }
}
