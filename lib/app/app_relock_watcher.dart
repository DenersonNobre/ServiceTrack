// Observador de ciclo de vida para bloqueio automático por inatividade/background.

import 'package:flutter/material.dart';

import 'app_routes.dart';

/// Widget observador de ciclo de vida da aplicação.
///
/// Monitora o tempo em que o app fica em segundo plano (paused/hidden).
/// Se o tempo exceder o TTL estipulado (padrão de 5 minutos), ao retornar (resumed)
/// dispara o relock navegando para [AppRoutes.lock] ou acionando [onRelock].
class AppRelockWatcher extends StatefulWidget {
  const AppRelockWatcher({
    super.key,
    required this.child,
    this.navigatorKey,
    this.timeout = const Duration(minutes: 5),
    this.onRelock,
    this.clock,
  });

  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;
  final Duration timeout;
  final VoidCallback? onRelock;
  final DateTime Function()? clock;

  @override
  State<AppRelockWatcher> createState() => _AppRelockWatcherState();
}

class _AppRelockWatcherState extends State<AppRelockWatcher>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  DateTime _now() => widget.clock != null ? widget.clock!() : DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundedAt ??= _now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final bgAt = _backgroundedAt;
      _backgroundedAt = null;
      if (bgAt == null) return;

      if (_now().difference(bgAt) > widget.timeout) {
        _triggerRelock();
      }
    }
  }

  void _triggerRelock() {
    if (widget.onRelock != null) {
      widget.onRelock!();
      return;
    }

    final navState = widget.navigatorKey?.currentState;
    if (navState != null) {
      navState.pushReplacementNamed(AppRoutes.lock);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
