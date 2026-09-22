// theme.dart
// ----------
// Assembles Flutter ThemeData from tokens, colours, and typography,
// aligned to the daisyUI 5 design system:
//   • base-100/200/300 surfaces + semantic tokens (via AppColours)
//   • radius-field (buttons/inputs), radius-box (cards/sheets)
//   • flat surfaces (no glow), base-300 hairline borders
//   • dark is the default theme; light mirrors daisyUI's light brand
//
// Design rules preserved:
//   D1  60px minimum tap targets
//   D2  No colour for status — error only on destructive confirm
//   D4  19pt body text

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'colours.dart';
import 'accents.dart';
import 'typography.dart';
import 'tokens.dart';

ThemeData buildTheme({required Brightness brightness, bool compact = false}) {
  final colours = brightness == Brightness.light
      ? AppColours.light
      : AppColours.dark;

  final textTheme = buildTextTheme(colours, compact: compact);

  // ── Shared helpers ──────────────────────────────────────────────────
  final hairline = BorderSide(color: colours.outline, width: 1);
  final cardRadius = BorderRadius.circular(AppTokens.radiusBox);
  final fieldRadius = BorderRadius.circular(AppTokens.radiusField);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colours,
    textTheme: textTheme,
    materialTapTargetSize: MaterialTapTargetSize.padded,

    // ── Scaffold — daisyUI base-100 ─────────────────────────────────────
    scaffoldBackgroundColor: colours.surface,

    // ── Card — daisyUI Card: base-100/200 fill + base-300 hairline ──────
    cardTheme: CardThemeData(
      color: colours.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: hairline,
      ),
      margin: const EdgeInsets.symmetric(vertical: AppTokens.cardGap / 2),
    ),

    // ── Filled button — daisyUI btn-primary (solid, radius-field) ───────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colours.primary,
        foregroundColor: colours.onPrimary,
        minimumSize: const Size(0, AppTokens.targetMin),
        shape: RoundedRectangleBorder(borderRadius: fieldRadius),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space6,
          vertical: AppTokens.space3,
        ),
        textStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: AppTokens.textBody,
        ),
        elevation: 0,
      ),
    ),

    // ── Elevated button — treated like btn-primary too ──────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colours.primary,
        foregroundColor: colours.onPrimary,
        minimumSize: const Size(0, AppTokens.targetMin),
        shape: RoundedRectangleBorder(borderRadius: fieldRadius),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space6,
          vertical: AppTokens.space3,
        ),
        textStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: AppTokens.textBody,
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),

    // ── Outlined button — daisyUI btn-outline (base-300 border) ─────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colours.onSurface,
        minimumSize: const Size(0, AppTokens.targetMin),
        shape: RoundedRectangleBorder(borderRadius: fieldRadius),
        side: hairline,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space6,
          vertical: AppTokens.space3,
        ),
        textStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: AppTokens.textBody,
        ),
      ),
    ),

    // ── Text button — daisyUI btn-ghost (primary label) ─────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colours.primary,
        minimumSize: const Size(AppTokens.targetMin, AppTokens.targetMin),
        shape: RoundedRectangleBorder(borderRadius: fieldRadius),
        textStyle: textTheme.bodyLarge,
      ),
    ),

    // ── Input fields — daisyUI input (base-200 fill, primary focus) ─────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colours.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: hairline,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: hairline,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: colours.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space4,
      ),
      hintStyle: textTheme.bodyLarge?.copyWith(color: colours.onSurfaceVariant),
    ),

    // ── AppBar — flat base-100 ──────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: colours.surface,
      foregroundColor: colours.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.headlineMedium,
    ),

    // ── Bottom Navigation Bar — daisyUI Dock (base-300) ─────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colours.surfaceContainerHighest,
      indicatorColor: AppAccents.skyTint10,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSelector),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: AppTokens.textCaption,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? colours.primary : colours.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colours.primary : colours.onSurfaceVariant,
          size: 24,
        );
      }),
      height: 68,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
    ),

    // ── Navigation Rail — daisyUI Menu (base-300) ───────────────────────
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colours.surfaceContainerHighest,
      indicatorColor: AppAccents.skyTint10,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSelector),
      ),
      selectedIconTheme: IconThemeData(color: colours.primary),
      unselectedIconTheme: IconThemeData(color: colours.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: colours.primary,
        fontSize: AppTokens.textCaption,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colours.onSurfaceVariant,
        fontSize: AppTokens.textCaption,
      ),
    ),

    // ── List tiles ───────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: AppTokens.space3,
      minLeadingWidth: AppTokens.targetMin,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppTokens.screenEdge,
        vertical: AppTokens.space3,
      ),
    ),

    // ── Dividers — base-300 hairlines ────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: colours.outline,
      thickness: 1,
      space: 0,
    ),

    // ── Dialogs / sheets — daisyUI Modal (radius-box) ───────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: colours.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusBox),
        side: hairline,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colours.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusBox),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colours.surfaceContainerHighest,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: colours.onSurface),
      actionTextColor: colours.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
      ),
    ),

    // ── Page transitions ─────────────────────────────────────────────────
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS:   CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux:   FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
