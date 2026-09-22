// lib/features/dashboard/charts/type_bars.dart
// ---------------------------------------------
// Per-bill-type totals as ranked horizontal bars — the "track each expense"
// view. Each bar uses its category colour (Law of Similarity: same colour
// language as the tiles and the Bills filter) and carries a word + amount
// label so meaning never rests on colour alone (D2). Tapping a bar selects
// that type so the screen can show its own trend.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/components/category_icons.dart';
import '../../../shared/models/spend_summary.dart';
import '../../../theme/tokens.dart';

class TypeBars extends StatelessWidget {
  const TypeBars({
    super.key,
    required this.types,
    this.selected,
    this.onSelect,
  });

  final List<TypeTotal> types;

  /// Currently highlighted service type, if any.
  final String? selected;

  /// Called when a bar is tapped (its serviceType).
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final currency = NumberFormat.currency(symbol: r'$');

    final maxTotal =
        types.fold<double>(0, (m, t) => t.total > m ? t.total : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < types.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTokens.space4),
          _Bar(
            type: types[i],
            amount: currency.format(types[i].total),
            fraction: maxTotal == 0 ? 0 : types[i].total / maxTotal,
            fill: CategoryIcons.colorForKind(
              CategoryIcons.kindFor(types[i].serviceType,
                  serviceType: types[i].serviceType),
            ),
            isSelected: types[i].serviceType == selected,
            text: text,
            colours: colours,
            onTap: onSelect == null
                ? null
                : () => onSelect!(types[i].serviceType),
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.type,
    required this.amount,
    required this.fraction,
    required this.fill,
    required this.isSelected,
    required this.text,
    required this.colours,
    required this.onTap,
  });

  final TypeTotal type;
  final String amount;
  final double fraction;
  final Color fill;
  final bool isSelected;
  final TextTheme text;
  final ColorScheme colours;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = CategoryIcons.iconForKind(
        CategoryIcons.kindFor(type.serviceType, serviceType: type.serviceType));

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: '${type.label} $amount',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: fill),
                    const SizedBox(width: AppTokens.space2),
                    Expanded(
                      child: Text(
                        type.label,
                        style: text.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Text(
                      amount,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  child: Stack(
                    children: [
                      Container(
                        height: 12,
                        color: colours.onSurface.withValues(alpha: 0.06),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.02, 1.0),
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? fill
                                : fill.withValues(alpha: 0.85),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusSm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
