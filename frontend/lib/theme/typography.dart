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

TextTheme buildTextTheme(ColorScheme colours, {bool compact = false}) {
  // Pick the size set: compact (phone < 400pt) tightens the whole scale.
  final sAmount     = compact ? AppTokens.textAmountC     : AppTokens.textAmount;
  final sLargeTitle = compact ? AppTokens.textLargeTitleC : AppTokens.textLargeTitle;
  final sBody       = compact ? AppTokens.textBodyC       : AppTokens.textBody;
  final sTitle1     = compact ? AppTokens.textTitle1C     : AppTokens.textTitle1;
  final sTitle3     = compact ? AppTokens.textTitle3C     : AppTokens.textTitle3;
  final sHeadline   = compact ? AppTokens.textHeadlineC   : AppTokens.textHeadline;
  final sSubhead    = compact ? AppTokens.textSubheadC    : AppTokens.textSubhead;
  final sFootnote   = compact ? AppTokens.textFootnoteC   : AppTokens.textFootnote;
  final sCaption    = compact ? AppTokens.textCaptionC    : AppTokens.textCaption;

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
      size: sAmount,
      weight: FontWeight.w700,
      height: 1.1,
      features: const [FontFeature.tabularFigures()],
    ),

    // ── Display — onboarding hero ─────────────────────────────────────
    displayMedium: inter(
      size: sLargeTitle,
      weight: FontWeight.w700,
      height: 1.15,
    ),

    // ── Headline — screen section titles ──────────────────────────────
    headlineLarge: inter(
      size: sTitle1,
      weight: FontWeight.w700,
      height: 1.15,
    ),

    // ── Headline — section headers, provider names ────────────────────
    headlineMedium: inter(
      size: sTitle3,
      weight: FontWeight.w600,
    ),

    // ── Title — interpretation sentence / card labels ─────────────────
    titleLarge: inter(
      size: sHeadline,
      weight: FontWeight.w600,
    ),

    // ── Body — base: 16pt default body text ───────────────────────────
    bodyLarge: inter(size: sBody),

    // ── Body — secondary detail / subhead ─────────────────────────────
    bodyMedium: inter(
      size: sSubhead,
      color: colours.onSurfaceVariant,
    ),

    // ── Body small — dates, metadata ─────────────────────────────────
    bodySmall: inter(
      size: sFootnote,
      color: colours.onSurfaceVariant,
    ),

    // ── Label — provenance, captions (floor) ──────────────────────────
    labelSmall: inter(
      size: sCaption,
      color: colours.onSurfaceVariant,
    ),
  );
}
