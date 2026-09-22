// lib/features/dashboard/charts/provider_bars.dart
// -------------------------------------------------
// Per-provider totals as ranked horizontal bars (Miller / Serial Position:
// strongest first). Each bar carries a WORD + amount label — the bar length
// is illustrative, the words carry the meaning (D2). Neutral graphite fill.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/spend_summary.dart';
import '../../../theme/tokens.dart';
import '../chart_palette.dart';

class ProviderBars extends StatelessWidget {
  const ProviderBars({super.key, required this.providers});

  final List<ProviderTotal> providers;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final currency = NumberFormat.currency(symbol: r'$');

    final maxTotal =
        providers.fold<double>(0, (m, p) => p.total > m ? p.total : m);
    final ramp = ChartPalette.ramp(colours, providers.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < providers.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTokens.space4),
          _Bar(
            label: providers[i].provider,
            sublabel: providers[i].serviceType,
            amount: currency.format(providers[i].total),
            fraction: maxTotal == 0 ? 0 : providers[i].total / maxTotal,
            fill: ramp[i],
            text: text,
            colours: colours,
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.sublabel,
    required this.amount,
    required this.fraction,
    required this.fill,
    required this.text,
    required this.colours,
  });

  final String label;
  final String sublabel;
  final String amount;
  final double fraction;
  final Color fill;
  final TextTheme text;
  final ColorScheme colours;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '$label · ${_titleCase(sublabel)}',
                style: text.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppTokens.space3),
            Text(
              amount,
              style: text.bodyMedium?.copyWith(
                fontFeatures: const [], // tabular handled by theme
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
                    color: fill,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
