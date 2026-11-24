// Widget raiz do aplicativo ServiceTrack (composição de tema e serviços transversais).

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import 'app_entry.dart';
import 'app_services.dart';
import 'theme/app_theme.dart';

/// Aplicativo raiz do ServiceTrack (standalone).
class App extends StatelessWidget {
  /// Cria o app; serviços transversais podem ser injetados em testes ou derivados do [database].
  const App({
    super.key,
    this.database,
    this.services,
  });

  /// Instância do banco SQLite local (opcional para testes unitários).
  final SqliteProvider? database;

  /// Serviços transversais agregados da aplicação (opcional para injeção em testes).
  final AppServices? services;

  @override
  Widget build(BuildContext context) {
    final appServices =
        services ?? AppServices.fromDatabase(database: database);
    final db = database ?? appServices.database;

    return KortexMaterialApp(
      providers: [
        KortexProvider<AppServices>.value(value: appServices),
        if (db != null) KortexProvider<SqliteProvider>.value(value: db),
      ],
      app: MaterialApp(
        title: 'ServiceTrack',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        home: AppEntry(services: appServices),
      ),
    );
  }
}
