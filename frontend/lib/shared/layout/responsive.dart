// responsive.dart
// ----------------
// Breakpoint helpers and a responsive scaffold used across the app.
//
// Design pillars honored:
//   D3 (chrome-light): navigation is quiet — a bottom bar on mobile,
//                       a left rail on desktop, nothing more.
//   Responsive: layout adapts structurally (nav switches, content
//               centers at a max width) — never fluid typography.
//
// Breakpoints (logical pixels / points) — daisyUI 5 breakpoint reference:
//   mobile   < 640        (no prefix)
//   sm/md    640 – 1024   (sm ≥ 640, md ≥ 768)
//   desktop  >= 1024      (lg / xl)
//
// The 640pt line (daisyUI `sm`) is where we swap the bottom NavigationBar
// (daisyUI Dock) for a left NavigationRail (daisyUI Menu).

import 'package:flutter/widgets.dart';
import '../../theme/tokens.dart';

/// Named device classes derived from the shortest usable width.
enum DeviceClass { mobile, tablet, desktop }

class Breakpoints {
  Breakpoints._();

  /// Below this, use a bottom navigation bar (mobile). daisyUI `sm` = 640.
  static const double mobileMax = AppTokens.desktopBreakpoint; // 640

  /// Below this, treat as tablet; at/above, desktop. daisyUI `lg` = 1024.
  static const double tabletMax = AppTokens.bpLg; // 1024

  static DeviceClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static DeviceClass fromWidth(double width) {
    if (width < mobileMax) return DeviceClass.mobile;
    if (width < tabletMax) return DeviceClass.tablet;
    return DeviceClass.desktop;
  }

  /// True when navigation should be a left rail rather than a bottom bar.
  static bool useRail(double width) => width >= mobileMax;

  static bool isMobile(BuildContext context) =>
      of(context) == DeviceClass.mobile;

  static bool isDesktop(BuildContext context) =>
      of(context) == DeviceClass.desktop;

  /// True on narrow phones (< 400pt) where type/spacing should tighten the
  /// most. Distinct from [isMobile] (which covers larger phones/tablets too).
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 400;
}

/// Centers page content at a comfortable maximum width on wide screens
/// and lets it run full-bleed on mobile. Keeps the one-sentence cards
/// from stretching uncomfortably wide on a laptop.
class CenteredContent extends StatelessWidget {
  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = AppTokens.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Lays out children in a single column on mobile and a responsive
/// grid on wider screens. Used by the dashboard chart cards.
///
/// [columnsWide] controls how many columns to use at tablet/desktop.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columnsWide = 2,
    this.gap = AppTokens.space4,
  });

  final List<Widget> children;
  final int columnsWide;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= Breakpoints.mobileMax;
      if (!isWide) {
        // Single column, stacked with gaps.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              children[i],
            ],
          ],
        );
      }

      final columns =
          columnsWide.clamp(1, children.isEmpty ? 1 : children.length);
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += columns) {
        final rowChildren = <Widget>[];
        for (var c = 0; c < columns; c++) {
          final idx = i + c;
          if (c > 0) rowChildren.add(SizedBox(width: gap));
          rowChildren.add(
            Expanded(
              child: idx < children.length
                  ? children[idx]
                  : const SizedBox.shrink(),
            ),
          );
        }
        if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
        rows.add(IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowChildren,
          ),
        ));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      );
    });
  }
}
