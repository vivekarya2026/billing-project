// lib/features/dashboard/charts/category_donut.dart
// --------------------------------------------------
// Charge categories (Charges / Taxes / Fees …) as a donut with a
// word + value legend beside it. Neutral graphite ramp — segments are
// labelled by words, not color-coded status (D2). Reduced motion honored.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/spend_summary.dart';
import '../../../theme/tokens.dart';
import '../chart_palette.dart';

class CategoryDonut extends StatelessWidget {
  const CategoryDonut({super.key, required this.categories});

  final List<CategoryTotal> categories;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final currency = NumberFormat.currency(symbol: r'$');

    final total =
        categories.fold<double>(0, (s, c) => s + (c.total > 0 ? c.total : 0));
    final ramp = ChartPalette.ramp(colours, categories.length);

    final donut = SizedBox(
      height: 150,
      width: 150,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 44,
          sections: [
            for (var i = 0; i < categories.length; i++)
              PieChartSectionData(
                value: categories[i].total.abs(),
                color: ramp[i],
                radius: 26,
                showTitle: false,
              ),
          ],
        ),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < categories.length; i++) ...[
          if (i > 0) const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: ramp[i],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Text(categories[i].category, style: text.bodyMedium),
              ),
              const SizedBox(width: AppTokens.space2),
              Text(
                currency.format(categories[i].total),
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: AppTokens.space2),
              Text(
                total == 0
                    ? ''
                    : '${((categories[i].total / total) * 100).round()}%',
                style: text.labelSmall
                    ?.copyWith(color: ChartPalette.axisLabel(colours)),
              ),
            ],
          ),
        ],
      ],
    );

    // Donut left, legend right — wraps to stacked on very narrow widths.
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 320) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: donut),
            const SizedBox(height: AppTokens.space5),
            legend,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          donut,
          const SizedBox(width: AppTokens.space6),
          Expanded(child: legend),
        ],
      );
    });
  }
}
