// Widget raiz do aplicativo ServiceTrack (composição de tema e serviços transversais).

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import 'app_pages.dart';
import 'app_relock_watcher.dart';
import 'app_routes.dart';
import 'app_services.dart';
import 'theme/app_theme.dart';

/// Aplicativo raiz do ServiceTrack (standalone).
class App extends StatefulWidget {
  /// Cria o app; serviços transversais podem ser injetados em testes ou derivados do [database].
  const App({
    super.key,
    this.database,
    this.services,
    this.navigatorKey,
  });

  /// Instância do banco SQLite local (opcional para testes unitários).
  final SqliteProvider? database;

  /// Serviços transversais agregados da aplicação (opcional para injeção em testes).
  final AppServices? services;

  /// Chave de navegação global (opcional).
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final AppServices _appServices;
  late final AppPages _appPages;

  @override
  void initState() {
    super.initState();
    _navigatorKey = widget.navigatorKey ?? GlobalKey<NavigatorState>();
    _appServices =
        widget.services ?? AppServices.fromDatabase(database: widget.database);
    _appPages = AppPages(
      services: _appServices,
      navigatorKey: _navigatorKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = widget.database ?? _appServices.database;

    return KortexMaterialApp(
      providers: [
        KortexProvider<AppServices>.value(value: _appServices),
        if (db != null) KortexProvider<SqliteProvider>.value(value: db),
      ],
      app: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'ServiceTrack',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.initial,
        onGenerateRoute: _appPages.onGenerateRoute,
        builder: (context, child) => AppRelockWatcher(
          navigatorKey: _navigatorKey,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
