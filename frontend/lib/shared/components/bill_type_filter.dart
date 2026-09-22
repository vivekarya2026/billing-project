// bill_type_filter.dart — horizontally scrollable bill-type filter chips.
// ------------------------------------------------------------------------
// daisyUI *Filter*/*Tabs* semantics realised in Flutter. A radio-like set of
// chips: "All" (default, first — Serial-Position) then one chip per distinct
// service type present in the data, each carrying its CategoryIcons glyph and
// pastel colour (Law of Similarity — the same colour language as the tiles).
//
// UX rules honoured:
//   • Hick's Law: only the types that actually exist are shown; the row
//     scrolls horizontally rather than wrapping into a wall of choices.
//   • Fitts's Law: each chip is >=44px tall with generous padding.
//   • Doherty: selection state animates within ~200ms (content-reveal token).
//   • Reduced motion: colour/shape transitions only (no slide/scale), so they
//     stay comfortable when the OS asks for reduced motion.

import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'category_icons.dart';

/// Sentinel meaning "no type filter" (the All chip).
const String kAllBillTypes = '__all__';

class BillTypeFilter extends StatelessWidget {
  const BillTypeFilter({
    super.key,
    required this.types,
    required this.selected,
    required this.onSelected,
    this.counts,
  });

  /// Distinct service types present in the data, in display order.
  final List<String> types;

  /// Currently selected type, or [kAllBillTypes].
  final String selected;

  final ValueChanged<String> onSelected;

  /// Optional per-type counts (and an [kAllBillTypes] entry for the total),
  /// shown as a trailing number on each chip.
  final Map<String, int>? counts;

  @override
  Widget build(BuildContext context) {
    final entries = <String>[kAllBillTypes, ...types];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.screenEdge),
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space2),
        itemBuilder: (context, i) {
          final type = entries[i];
          final isAll = type == kAllBillTypes;
          return _FilterChip(
            label: isAll ? 'All' : CategoryIcons.labelForServiceType(type),
            icon: isAll
                ? Icons.tune
                : CategoryIcons.iconForKind(
                    CategoryIcons.kindFor(type, serviceType: type)),
            accent: isAll
                ? null
                : CategoryIcons.colorForKind(
                    CategoryIcons.kindFor(type, serviceType: type)),
            count: counts?[type],
            selected: type == selected,
            onTap: () => onSelected(type),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color? accent;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final glyph = accent ?? colours.primary;

    // Selected: filled with a faint tint of the accent + a solid border.
    // Unselected: quiet base-200 surface with a base-300 hairline (daisyUI).
    final bg = selected
        ? glyph.withValues(alpha: 0.16)
        : colours.surfaceContainer;
    final border = selected ? glyph.withValues(alpha: 0.9) : colours.outline;
    final fg = selected ? colours.onSurface : colours.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label filter',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusSelector),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space4, vertical: AppTokens.space2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppTokens.radiusSelector),
              border: Border.all(
                  color: border, width: selected ? 1.2 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: selected ? glyph : fg),
                const SizedBox(width: AppTokens.space2),
                Text(
                  label,
                  style: text.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: AppTokens.space2),
                  Text(
                    '$count',
                    style: text.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.7),
                      fontFeatures: const [],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
