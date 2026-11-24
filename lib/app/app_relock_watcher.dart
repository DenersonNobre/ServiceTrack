// Observador de ciclo de vida para bloqueio automático após inatividade.

import 'package:flutter/widgets.dart';

import 'routes/app_routes.dart';

/// Monitor de ciclo de vida da aplicação que força a navegação para [AppRoutes.lock]
/// quando o aplicativo fica suspenso em background além do tempo limite seguro.
class AppRelockWatcher extends StatefulWidget {
  const AppRelockWatcher({
    super.key,
    required this.child,
    this.navigatorKey,
    this.onRelock,
    this.timeout = const Duration(minutes: 5),
    this.clock = DateTime.now,
  });

  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;
  final VoidCallback? onRelock;
  final Duration timeout;
  final DateTime Function() clock;

  @override
  State<AppRelockWatcher> createState() => _AppRelockWatcherState();
}

class _AppRelockWatcherState extends State<AppRelockWatcher>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

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
    if (state == AppLifecycleState.paused) {
      _pausedAt = widget.clock();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final elapsed = widget.clock().difference(_pausedAt!);
        _pausedAt = null;
        if (elapsed >= widget.timeout) {
          _triggerRelock();
        }
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
