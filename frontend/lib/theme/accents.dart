// accents.dart
// ------------
// Semantic + decorative helpers, aligned to the daisyUI 5 design system.
//
// daisyUI leads with clean flat surfaces and semantic colour tokens rather
// than heavy gradients/glows. This file now exposes:
//   • daisyUI semantic status colours (success / warning / error / info)
//     and their soft tints (the daisyUI `*-soft` treatment).
//   • A `gradientText` helper kept for API compatibility — it now renders a
//     clean SOLID brand colour by default (no gradient), so existing call
//     sites read as daisyUI headings. Pass a gradient explicitly to opt in.
//
// Colours are the exact daisyUI values converted from oklch() to sRGB.

import 'package:flutter/material.dart';

class AppAccents {
  AppAccents._();

  // ── daisyUI semantic status tokens ────────────────────────────────────
  /// success — oklch(65% .20 145)
  static const Color success = Color(0xFF11AD32);
  /// warning — oklch(75% .22 75)
  static const Color warning = Color(0xFFFC9200);
  /// error — oklch(60% .22 25)  (also used for "you owe" / overdue / danger)
  static const Color error   = Color(0xFFE62B34);
  /// info — oklch(70% .18 220)
  static const Color info    = Color(0xFF00B5EB);

  /// Back-compat alias: "danger" == daisyUI error.
  static const Color danger  = error;

  // Soft tints — daisyUI `*-soft` (semantic colour at low alpha).
  static const Color successTint = Color(0x2211AD32);
  static const Color warningTint = Color(0x22FC9200);
  static const Color dangerTint  = Color(0x22E62B34);
  static const Color infoTint    = Color(0x2200B5EB);

  // ── Brand tint (primary at low alpha) — selection / active surfaces ───
  /// Faint primary tint for selected chips, nav indicators, badges.
  static const Color skyTint10 = Color(0x1A006FEA);
  static const Color skyBorder20 = Color(0x33006FEA);
  static const Color indigoTint10 = Color(0x1A00B093);
  static const Color emeraldDot = success;

  // ── Optional gradients (opt-in only) ──────────────────────────────────
  // daisyUI is flat by default; these remain for the rare hero accent.
  static const LinearGradient skyToBlue = LinearGradient(
    colors: [Color(0xFF00B5EB), Color(0xFF006FEA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient skyToIndigo = LinearGradient(
    colors: [Color(0xFF00B5EB), Color(0xFF006FEA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient skyToIndigoH = LinearGradient(
    colors: [Color(0xFF00B5EB), Color(0xFF006FEA)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Neutral (flat) — daisyUI has no glow; these are inert now ─────────
  static const BoxShadow glowSky  = BoxShadow(color: Color(0x00000000), blurRadius: 0);
  static const BoxShadow glowCard = BoxShadow(color: Color(0x00000000), blurRadius: 0);
  static const BoxShadow glowBadge = BoxShadow(color: Color(0x00000000), blurRadius: 0);

  /// Heading helper. By default renders a CLEAN SOLID colour (daisyUI style):
  /// if [solidColor] is provided it wins; otherwise, when a [gradient] is
  /// explicitly passed, it uses the gradient; else falls back to the theme's
  /// onSurface via the given [style] colour.
  static Widget gradientText(
    String text, {
    TextStyle? style,
    LinearGradient? gradient,
    Color? solidColor,
    TextAlign textAlign = TextAlign.start,
  }) {
    // Solid path (default daisyUI look).
    if (gradient == null) {
      return Text(
        text,
        style: solidColor != null ? style?.copyWith(color: solidColor) : style,
        textAlign: textAlign,
      );
    }
    // Opt-in gradient path.
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: style, textAlign: textAlign),
    );
  }

  /// Default currency symbol (₹ — Indian Rupee)
  static const String currencySymbol = '₹';
}
