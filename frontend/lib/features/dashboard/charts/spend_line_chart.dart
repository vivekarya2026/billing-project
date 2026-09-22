// lib/features/dashboard/charts/spend_line_chart.dart
// ----------------------------------------------------
// Total monthly spend over time. Neutral graphite stroke (D2), muted
// grid, tabular currency axis labels. Tapping a point calls [onSelectMonth].
// Animation is disabled when the OS asks for reduced motion.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/spend_summary.dart';
import '../../../theme/tokens.dart';
import '../chart_palette.dart';

class SpendLineChart extends StatelessWidget {
  const SpendLineChart({
    super.key,
    required this.monthly,
    this.onSelectMonth,
  });

  final List<MonthlyTotal> monthly;
  final ValueChanged<DateTime>? onSelectMonth;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final spots = <FlSpot>[
      for (var i = 0; i < monthly.length; i++)
        FlSpot(i.toDouble(), monthly[i].total),
    ];

    final maxY = monthly.fold<double>(0, (m, e) => e.total > m ? e.total : m);
    final niceMax = (maxY / 50).ceil() * 50 + 50;
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: niceMax.toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: niceMax / 4,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: ChartPalette.grid(colours), strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: niceMax / 2,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: AppTokens.space2),
                  child: Text(
                    currency.format(value),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                style: text.labelSmall
                        ?.copyWith(color: ChartPalette.axisLabel(colours)),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= monthly.length) {
                    return const SizedBox.shrink();
                  }
                  // Label every other month to avoid crowding.
                  if (monthly.length > 6 && i % 2 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: AppTokens.space2),
                    child: Text(
                      DateFormat('MMM').format(monthly[i].month),
                      style: text.labelSmall
                          ?.copyWith(color: ChartPalette.axisLabel(colours)),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: onSelectMonth != null,
            touchCallback: (event, resp) {
              if (event is FlTapUpEvent &&
                  resp?.lineBarSpots != null &&
                  resp!.lineBarSpots!.isNotEmpty) {
                final i = resp.lineBarSpots!.first.x.round();
                if (i >= 0 && i < monthly.length) {
                  onSelectMonth?.call(monthly[i].month);
                }
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => colours.onSurface,
              getTooltipItems: (spots) => spots.map((s) {
                final m = monthly[s.x.round()];
                return LineTooltipItem(
                  '${DateFormat('MMMM yyyy').format(m.month)}\n'
                  '${currency.format(m.total)}',
                  text.labelMedium!.copyWith(color: colours.surface),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: ChartPalette.lineStroke(colours),
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(
                  radius: 3,
                  color: colours.surface,
                  strokeWidth: 2,
                  strokeColor: ChartPalette.lineStroke(colours),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ChartPalette.lineStroke(colours).withValues(alpha: 0.15),
                    ChartPalette.lineStroke(colours).withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
