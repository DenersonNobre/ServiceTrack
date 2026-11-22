// Guarda de orientação por classe de dispositivo (PRD RNF-05 / DESIGN §5).
//
// SRP: aplicar trava Portrait-Only em smartphones (< 600dp) e liberar
// Landscape apenas em tablets (>= 600dp).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Breakpoint canônico entre smartphone e tablet em dp.
const double kTabletBreakpointDp = 600;

/// Aplica a política de orientação do aplicativo conforme o tamanho da tela.
void applyDeviceOrientationPolicy() {
  final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
  if (view == null) return;
  final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortestSide < kTabletBreakpointDp) {
    // ignore: discarded_futures
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}
