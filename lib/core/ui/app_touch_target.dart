// Tokens de acessibilidade e alvo tátil de campo (Styleguide v2.1).
//
// SRP: centralizar as dimensões mínimas de 48dp exigidas para botões e
// controles interativos usados em campo.

import 'package:flutter/widgets.dart';

/// Dimensão linear mínima de alvo tátil em pixels lógicos (48dp).
const double kMinTouchTargetEdge = 48.0;

/// Tamanho mínimo quadrado de alvo tátil (48dp x 48dp).
const Size kMinTouchTargetSize = Size(
  kMinTouchTargetEdge,
  kMinTouchTargetEdge,
);

/// Altura mínima de alvo tátil para botões full-width (largura infinita x 48dp).
const Size kMinTouchTargetHeight = Size.fromHeight(kMinTouchTargetEdge);

/// Constraints mínimas de alvo tátil (48dp x 48dp).
const BoxConstraints kMinTouchTargetConstraints = BoxConstraints(
  minWidth: kMinTouchTargetEdge,
  minHeight: kMinTouchTargetEdge,
);
