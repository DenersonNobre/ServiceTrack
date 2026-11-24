// Raiz de aplicação Kortex para MaterialApp e CupertinoApp (IoC com tipagem estrita).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';

/// Raiz reativa do aplicativo baseada em Material Design com injeção via [KortexScope].
///
/// Adota inversão de controle exigindo explicitamente um [MaterialApp] configurado,
/// sem replicar os parâmetros do framework e garantindo tipagem estrita.
final class KortexMaterialApp extends StatelessWidget {
  /// Cria um [KortexMaterialApp].
  const KortexMaterialApp({
    super.key,
    required this.providers,
    required this.app,
  });

  /// Lista de provedores gerenciados pelo escopo raiz.
  final List<KortexProvider<Object>> providers;

  /// Instância de [MaterialApp] encapsulada pelo escopo.
  final MaterialApp app;

  @override
  Widget build(BuildContext context) {
    return KortexScope(
      providers: providers,
      child: app,
    );
  }
}

/// Raiz reativa do aplicativo baseada em Cupertino com injeção via [KortexScope].
///
/// Adota inversão de controle exigindo explicitamente um [CupertinoApp] configurado,
/// sem replicar os parâmetros do framework e garantindo tipagem estrita.
final class KortexCupertinoApp extends StatelessWidget {
  /// Cria um [KortexCupertinoApp].
  const KortexCupertinoApp({
    super.key,
    required this.providers,
    required this.app,
  });

  /// Lista de provedores gerenciados pelo escopo raiz.
  final List<KortexProvider<Object>> providers;

  /// Instância de [CupertinoApp] encapsulada pelo escopo.
  final CupertinoApp app;

  @override
  Widget build(BuildContext context) {
    return KortexScope(
      providers: providers,
      child: app,
    );
  }
}
