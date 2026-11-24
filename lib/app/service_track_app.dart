// Widget raiz do aplicativo ServiceTrack (composição de tema e portas).

import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_lib/sqlite/sqlite.dart';

import 'app_dependencies.dart';
import 'app_entry.dart';
import 'theme/app_theme.dart';

/// Aplicativo raiz do ServiceTrack (standalone).
class ServiceTrackApp extends StatelessWidget {
  /// Cria o app; dependências podem ser injetadas em testes ou derivadas do [database].
  const ServiceTrackApp({
    super.key,
    this.database,
    this.dependencies,
  });

  /// Instância do banco SQLite local (opcional para testes unitários).
  final SqliteProvider? database;

  /// Dependências agregadas da aplicação (opcional para injeção em testes).
  final AppDependencies? dependencies;

  @override
  Widget build(BuildContext context) {
    final deps =
        dependencies ?? AppDependencies.fromDatabase(database: database);
    final db = database;

    return KortexMaterialApp(
      providers: [
        KortexProvider<AppDependencies>.value(value: deps),
        if (db != null) KortexProvider<SqliteProvider>.value(value: db),
      ],
      app: MaterialApp(
        title: 'ServiceTrack',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        home: AppEntry(deps: deps),
      ),
    );
  }
}
