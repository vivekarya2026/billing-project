// typography.dart
// ---------------
// Type scale — Inter throughout, matching the daisyUI 5 design system's
// `--font-sans: "Inter"`. Inter is bundled locally (assets/fonts) so it ships
// with the app — no runtime Google Fonts CDN fetch.
//
// Rules:
//   - Base body is 16pt (calm, low cognitive load)
//   - The amount (textAmount) is the LARGEST element on screen
//   - 12pt is the floor — nothing smaller ships
//   - Tabular figures for all currency: fontFeatures: [FontFeature.tabularFigures()]
//   - Dynamic Type: all styles respond to MediaQuery.textScaler

import 'package:flutter/material.dart';
import 'tokens.dart';

TextTheme buildTextTheme(ColorScheme colours) {
  TextStyle inter({
    required double size,
    FontWeight weight = FontWeight.normal,
    double height = 1.4,
    Color? color,
    List<FontFeature>? features,
  }) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? colours.onSurface,
        fontFeatures: features,
      );

  return TextTheme(
    // ── Display — the dollar amount, largest on screen ────────────────
    displayLarge: inter(
      size: AppTokens.textAmount,
      weight: FontWeight.w700,
      height: 1.1,
      features: const [FontFeature.tabularFigures()],
    ),

    // ── Display — onboarding hero ─────────────────────────────────────
    displayMedium: inter(
      size: AppTokens.textLargeTitle,
      weight: FontWeight.w700,
      height: 1.15,
    ),

    // ── Headline — screen section titles ──────────────────────────────
    headlineLarge: inter(
      size: AppTokens.textTitle1,
      weight: FontWeight.w700,
      height: 1.15,
    ),

    // ── Headline — section headers, provider names ────────────────────
    headlineMedium: inter(
      size: AppTokens.textTitle3,
      weight: FontWeight.w600,
    ),

    // ── Title — interpretation sentence / card labels ─────────────────
    titleLarge: inter(
      size: AppTokens.textHeadline,
      weight: FontWeight.w600,
    ),

    // ── Body — base: 16pt default body text ───────────────────────────
    bodyLarge: inter(size: AppTokens.textBody),

    // ── Body — secondary detail / subhead ─────────────────────────────
    bodyMedium: inter(
      size: AppTokens.textSubhead,
      color: colours.onSurfaceVariant,
    ),

    // ── Body small — dates, metadata ─────────────────────────────────
    bodySmall: inter(
      size: AppTokens.textFootnote,
      color: colours.onSurfaceVariant,
    ),

    // ── Label — provenance, captions (floor: 12pt) ────────────────────
    labelSmall: inter(
      size: AppTokens.textCaption,
      color: colours.onSurfaceVariant,
    ),
  );
}
