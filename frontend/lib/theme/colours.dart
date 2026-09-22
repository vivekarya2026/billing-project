// colours.dart
// ------------
// Semantic colour tokens mapped from the **daisyUI 5 design system**.
//
// daisyUI exposes 20 semantic tokens (primary, secondary, accent, neutral,
// base-100/200/300, base-content, info/success/warning/error + *-content).
// We map those onto Flutter's ColorScheme:
//
//   daisyUI            → Flutter ColorScheme
//   base-100           → surface            (page background)
//   base-200           → surfaceContainer   (cards / inputs)
//   base-300           → surfaceContainerHighest + outline (borders/raised)
//   base-content       → onSurface
//   primary            → primary            (brand blue, oklch 55% .22 250)
//   secondary          → secondary          (teal,       oklch 65% .18 180)
//   accent             → tertiary           (amber,      oklch 70% .20 80)
//   error/success/…    → error + AppAccents semantic tokens
//
// Colours are the exact daisyUI values converted from oklch() to sRGB.
// Dark is the default theme; light mirrors daisyUI's light brand surfaces.

import 'package:flutter/material.dart';

class AppColours {
  AppColours._();

  // ── daisyUI brand tokens (shared across light + dark) ─────────────────
  static const Color _primary          = Color(0xFF006FEA); // oklch(55% .22 250)
  static const Color _primaryContent   = Color(0xFFF4F9FF); // oklch(98% .01 250)
  static const Color _secondary        = Color(0xFF00B093); // oklch(65% .18 180)
  static const Color _secondaryContent = Color(0xFFF2FBF9);
  static const Color _accent           = Color(0xFFDD8A00); // oklch(70% .20 80)
  static const Color _accentContent    = Color(0xFF100A03);

  static const Color _error            = Color(0xFFE62B34); // oklch(60% .22 25)

  // ── Dark (default) — daisyUI "dark" base surfaces ─────────────────────
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,

    // Surfaces — daisyUI dark base-100/200/300
    surface:                   Color(0xFF1D232A),  // base-100 (page bg)
    surfaceContainer:          Color(0xFF191E24),  // base-200 (cards/inputs)
    surfaceContainerHigh:      Color(0xFF191E24),  // alias
    surfaceContainerHighest:   Color(0xFF15191E),  // base-300 (raised / nav)

    // Text — daisyUI base-content
    onSurface:        Color(0xFFECF9FF),            // base-content
    onSurfaceVariant: Color(0xFF9CA6B4),            // muted base-content

    // Brand
    primary:    _primary,
    onPrimary:  _primaryContent,
    secondary:   _secondary,
    onSecondary: _secondaryContent,
    tertiary:    _accent,
    onTertiary:  _accentContent,

    // Destructive
    error:    _error,
    onError:  Color(0xFFFFFFFF),

    // Outline — base-300 (borders/dividers)
    outline: Color(0xFF2A3138),
  );

  // ── Light — daisyUI brand light surfaces ──────────────────────────────
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,

    surface:                 Color(0xFFFFFFFF),  // base-100
    surfaceContainer:        Color(0xFFF2F2F2),  // base-200
    surfaceContainerHigh:    Color(0xFFF2F2F2),
    surfaceContainerHighest: Color(0xFFDEDEDE),  // base-300

    onSurface:        Color(0xFF11161F),          // base-content
    onSurfaceVariant: Color(0xFF5B636E),          // muted base-content

    primary:    _primary,
    onPrimary:  _primaryContent,
    secondary:   _secondary,
    onSecondary: _secondaryContent,
    tertiary:    _accent,
    onTertiary:  _accentContent,

    error:    _error,
    onError:  Color(0xFFFFFFFF),

    outline:  Color(0xFFDEDEDE),                  // base-300
  );

  /// Helper: picks dark or light scheme based on the current theme.
  static ColorScheme resolveColours(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
