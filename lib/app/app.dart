// Widget raiz do aplicativo ServiceTrack (composição de tema e serviços transversais).

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import 'app_controller.dart';
import 'app_relock_watcher.dart';
import 'app_services.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

/// Aplicativo raiz do ServiceTrack (standalone).
///
/// Widget 100% puro e declarativo (`StatelessWidget`), delegando o gerenciamento
/// de estado e ciclo de vida ao [AppController].
class App extends StatelessWidget {
  /// Cria o app; aceita injeção direta de [controller] ou fabrica a partir de [database] e [services].
  const App({
    super.key,
    this.database,
    this.services,
    this.navigatorKey,
    this.controller,
  });

  /// Instância do banco SQLite local (opcional para testes unitários).
  final SqliteProvider? database;

  /// Serviços transversais agregados da aplicação (opcional para injeção em testes).
  final AppServices? services;

  /// Chave de navegação global (opcional).
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Controlador raiz da aplicação (se omitido, resolvido a partir de [services]/[database]).
  final AppController? controller;

  @override
  Widget build(BuildContext context) {
    final appController = controller ??
        AppController.fromDatabase(
          database: database,
          services: services,
          navigatorKey: navigatorKey,
        );

    final effectiveServices = appController.services;
    final db = database ?? effectiveServices.database;

    return KortexMaterialApp(
      providers: [
        KortexProvider<AppController>.value(value: appController),
        KortexProvider<AppServices>.value(value: effectiveServices),
        if (db != null) KortexProvider<SqliteProvider>.value(value: db),
      ],
      app: MaterialApp(
        navigatorKey: appController.navigatorKey,
        title: 'ServiceTrack',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: appController.themeMode.value,
        initialRoute: AppRoutes.initial,
        onGenerateRoute: appController.pages.onGenerateRoute,
        builder: (context, child) => AppRelockWatcher(
          navigatorKey: appController.navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
