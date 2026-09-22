// spacing.dart
// ------------
// Named spacing helpers built on the 8pt grid in AppTokens.
// Provides SizedBox shortcuts and EdgeInsets presets so
// no widget ever hardcodes a raw pixel value.

import 'package:flutter/widgets.dart';
import 'tokens.dart';

class AppSpacing {
  AppSpacing._();

  // ── Vertical gaps ────────────────────────────────────────────────────
  static const Widget v1  = SizedBox(height: AppTokens.space1);
  static const Widget v2  = SizedBox(height: AppTokens.space2);
  static const Widget v3  = SizedBox(height: AppTokens.space3);
  static const Widget v4  = SizedBox(height: AppTokens.space4);
  static const Widget v5  = SizedBox(height: AppTokens.space5);
  static const Widget v6  = SizedBox(height: AppTokens.space6);
  static const Widget v8  = SizedBox(height: AppTokens.space8);
  static const Widget v10 = SizedBox(height: AppTokens.space10);

  // ── Horizontal gaps ──────────────────────────────────────────────────
  static const Widget h2  = SizedBox(width: AppTokens.space2);
  static const Widget h3  = SizedBox(width: AppTokens.space3);
  static const Widget h4  = SizedBox(width: AppTokens.space4);

  // ── EdgeInsets presets ───────────────────────────────────────────────
  // Standard screen padding (left + right = screenEdge)
  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: AppTokens.screenEdge,
  );

  // Card internal padding
  static const EdgeInsets card = EdgeInsets.all(AppTokens.cardPad);

  // List row padding (60px minimum height via constraints, not padding)
  static const EdgeInsets row = EdgeInsets.symmetric(
    horizontal: AppTokens.screenEdge,
    vertical: AppTokens.space3,
  );

  // Primary button padding
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppTokens.space8,
    vertical: AppTokens.space4,
  );
}
