// lib/features/dashboard/chart_palette.dart
// ------------------------------------------
// Chart colour palette derived from the daisyUI 5 semantic tokens
// (primary / secondary / accent + neutral base tokens) rather than a
// hardcoded sky→indigo ramp. Works in both light and dark themes because
// every colour is pulled from the active ColorScheme.
//
// D2 preserved: colour alone never encodes a status judgment —
//               word+value labels always accompany every mark.

import 'package:flutter/material.dart';

class ChartPalette {
  ChartPalette._();

  // ── daisyUI categorical ramp (primary → secondary → accent → muted) ───
  /// n colours drawn from the theme's brand tokens, then muted neutrals.
  static List<Color> ramp(ColorScheme c, int n) {
    if (n <= 0) return const [];
    final brand = <Color>[c.primary, c.secondary, c.tertiary];
    if (n <= brand.length) return brand.sublist(0, n);

    // Beyond the three brand tokens, fade to a neutral base-content tint.
    final muted = c.onSurfaceVariant;
    final extra = <Color>[];
    for (var i = brand.length; i < n; i++) {
      final t = (i - brand.length) / ((n - brand.length).clamp(1, 999));
      extra.add(muted.withValues(alpha: 0.55 - (t * 0.25)));
    }
    return [...brand, ...extra];
  }

  // ── Line stroke — daisyUI primary ─────────────────────────────────────
  static Color lineStroke(ColorScheme c) => c.primary;

  /// No glow in the daisyUI (flat) look.
  static Color dotGlow(ColorScheme c) => Colors.transparent;

  // ── Grid / axis — base-300 / muted base-content ───────────────────────
  static Color grid(ColorScheme c) => c.outline.withValues(alpha: 0.6);

  static Color axisLabel(ColorScheme c) => c.onSurfaceVariant;

  // ── Selected / interactive mark accent ───────────────────────────────
  static Color accent(ColorScheme c) => c.primary;

  /// Flat look: no drop-shadow on selected marks.
  static List<BoxShadow> dotShadow(ColorScheme c) => const [];
}
