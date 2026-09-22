// tokens.dart
// -----------
// Single source of truth for spacing, radius, typography sizes,
// and layout breakpoints — aligned to the daisyUI 5 design system.
//
// daisyUI shape tokens (from the design system's theme):
//   --radius-selector: 0.5rem   → chips/toggles/small controls
//   --radius-field:    0.375rem → buttons, inputs, list rows
//   --radius-box:      0.75rem  → cards, modals, larger surfaces
// (1rem = 16 logical px.)
//
// All values are points (logical pixels).

class AppTokens {
  AppTokens._();

  // ── Spacing (8-pt grid) ────────────────────────────────────────────────
  static const double space1  =  4.0;
  static const double space2  =  8.0;
  static const double space3  = 12.0;
  static const double space4  = 16.0;
  static const double space5  = 20.0;
  static const double space6  = 24.0;
  static const double space7  = 32.0;
  static const double space8  = 40.0;
  static const double space9  = 48.0;
  static const double space10 = 64.0;

  // ── Screen edges ──────────────────────────────────────────────────────
  static const double screenEdge = 20.0;

  // ── Card ──────────────────────────────────────────────────────────────
  static const double cardPad = 16.0;
  static const double cardGap =  8.0;

  // ── Touch targets (D1 — 60 pt min; WCAG-compatible) ──────────────────
  static const double targetMin = 60.0;

  // ── Radii — daisyUI shape tokens ──────────────────────────────────────
  /// --radius-selector (0.5rem) — chips, toggles, small pills.
  static const double radiusSelector = 8.0;
  /// --radius-field (0.375rem) — buttons, inputs, list rows.
  static const double radiusField = 6.0;
  /// --radius-box (0.75rem) — cards, modals, sheets.
  static const double radiusBox = 12.0;

  // Back-compat aliases (map onto the daisyUI tokens above).
  static const double radiusSm   = radiusField;    // 6
  static const double radiusMd   = radiusSelector; // 8
  static const double radiusLg   = radiusBox;      // 12
  static const double radiusXl   = 16.0;
  static const double radiusFull = 100.0;

  // ── Typography sizes (base body = 16 pt — calmer, lower cognitive load) ─
  static const double textAmount     = 34.0;   // bill amount — still largest, not shouty
  static const double textLargeTitle = 26.0;   // onboarding headline
  static const double textBody       = 16.0;   // base body copy
  static const double textTitle1     = 22.0;   // h1 equivalent
  static const double textTitle2     = 19.0;   // h2 equivalent
  static const double textTitle3     = 17.0;   // h3 equivalent
  static const double textHeadline   = 15.0;   // semibold headline
  static const double textSubhead    = 14.0;   // secondary detail
  static const double textFootnote   = 12.0;   // dates, metadata (floor)
  static const double textCaption    = 12.0;   // captions/badges

  // ── Compact (phone < 400pt) type scale — tighter, less cognitive load ──
  //   Title 1/2/3: 22/19/17 → 22/18/16   Headline: 15 → 14
  //   Subhead: 14 → 12                     Footnote/caption floor: 12 → 10
  static const double textAmountC     = 28.0;  // amount — proportionally smaller
  static const double textLargeTitleC = 22.0;
  static const double textBodyC       = 14.0;
  static const double textTitle1C     = 22.0;
  static const double textTitle2C     = 18.0;
  static const double textTitle3C     = 16.0;
  static const double textHeadlineC   = 14.0;
  static const double textSubheadC    = 12.0;
  static const double textFootnoteC   = 10.0;
  static const double textCaptionC    = 10.0;

  // ── Layout / responsive (daisyUI breakpoints) ────────────────────────
  //   mobile  < 640   |  sm ≥ 640  |  md ≥ 768  |  lg ≥ 1024  |  2xl ≥ 1536
  /// Max content width on wide screens.
  static const double contentMaxWidth     = 880.0;
  /// Breakpoint above which we switch to the desktop rail layout.
  /// (Kept at 640 to match daisyUI's `sm` line.)
  static const double desktopBreakpoint   = 640.0;
  static const double bpSm  = 640.0;
  static const double bpMd  = 768.0;
  static const double bpLg  = 1024.0;
  static const double bp2xl = 1536.0;
  /// Action buttons are always in the bottom third of the screen.
  static const double actionAreaMinHeight = 120.0;
}
