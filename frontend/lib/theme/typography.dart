// typography.dart
// ---------------
// Type scale — Inter throughout, matching the daisyUI 5 design system's
// `--font-sans: "Inter"`. Clean sans headings replace the previous serif so
// the app reads as a daisyUI-styled product.
//
// Rules:
//   - D4: body is 19pt, not HIG's 17pt
//   - The amount (textAmount) is always the LARGEST element on screen
//   - 13pt is the floor — nothing smaller ships
//   - Tabular figures for all currency: fontFeatures: [FontFeature.tabularFigures()]
//   - Dynamic Type: all styles respond to MediaQuery.textScaler

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

TextTheme buildTextTheme(ColorScheme colours) {
  final interSans = GoogleFonts.inter(
    color: colours.onSurface,
    height: 1.4,
  );

  // Headings: Inter, tighter leading, semibold — daisyUI heading feel.
  final interDisplay = GoogleFonts.inter(
    color: colours.onSurface,
    height: 1.15,
  );

  return TextTheme(
    // ── Display — the dollar amount, largest on screen ────────────────
    displayLarge: interSans.copyWith(
      fontSize: AppTokens.textAmount,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.1,
    ),

    // ── Display — onboarding hero ─────────────────────────────────────
    displayMedium: interDisplay.copyWith(
      fontSize: AppTokens.textLargeTitle,
      fontWeight: FontWeight.w700,
    ),

    // ── Headline — screen section titles ──────────────────────────────
    headlineLarge: interDisplay.copyWith(
      fontSize: AppTokens.textTitle1,
      fontWeight: FontWeight.w700,
    ),

    // ── Headline — section headers, provider names ────────────────────
    headlineMedium: interSans.copyWith(
      fontSize: AppTokens.textTitle3,
      fontWeight: FontWeight.w600,
    ),

    // ── Title — interpretation sentence / card labels ─────────────────
    titleLarge: interSans.copyWith(
      fontSize: AppTokens.textHeadline,
      fontWeight: FontWeight.w600,
    ),

    // ── Body — D4: 19pt default body text ─────────────────────────────
    bodyLarge: interSans.copyWith(
      fontSize: AppTokens.textBody,
      fontWeight: FontWeight.normal,
    ),

    // ── Body — secondary detail / subhead ─────────────────────────────
    bodyMedium: interSans.copyWith(
      fontSize: AppTokens.textSubhead,
      fontWeight: FontWeight.normal,
      color: colours.onSurfaceVariant,
    ),

    // ── Body small — dates, metadata ─────────────────────────────────
    bodySmall: interSans.copyWith(
      fontSize: AppTokens.textFootnote,
      fontWeight: FontWeight.normal,
      color: colours.onSurfaceVariant,
    ),

    // ── Label — provenance, captions (floor: 13pt) ────────────────────
    labelSmall: interSans.copyWith(
      fontSize: AppTokens.textCaption,
      fontWeight: FontWeight.normal,
      color: colours.onSurfaceVariant,
    ),
  );
}
