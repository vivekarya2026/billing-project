// lib/features/dashboard/dashboard_screen.dart
// ---------------------------------------------
// The Insights surface — calm, word-first spend tracking (secondary to the
// Bills tab's one sentence).
//
// Reading order (Serial Position — strongest first, memorable last):
//   0. Plain-language headline (NOT a chart) — leads the viewport.
//   1. KPI stats (total / bills tracked / biggest type) — chunked (Miller).
//   2. Spend over time (line) — or a single type's trend when one is picked.
//   3. By bill type (ranked bars) — tap a type to track just that expense.
//   4. By provider (ranked bars).
//   5. Where it goes (category donut + word legend).
//   6. This vs last month (word verdict — never a red/green pill, D2).
//
// Loading = skeletons (Operate rule). Empty = teaching state.
// Every chart section carries a Semantics summary (the sentence, not pixels).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/components/category_icons.dart';
import '../../shared/data/bill_repository.dart';
import '../../shared/models/line_item.dart';
import '../../shared/models/spend_summary.dart';
import '../../shared/layout/responsive.dart';
import '../../theme/tokens.dart';
import 'section_card.dart';
import 'charts/spend_line_chart.dart';
import 'charts/provider_bars.dart';
import 'charts/category_donut.dart';
import 'charts/type_bars.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<SpendSummary> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<BillRepository>();
    _future = _buildSummary(repo);
  }

  Future<SpendSummary> _buildSummary(BillRepository repo) async {
    final bills = await repo.getAllBills();
    final ids = bills.map((b) => b.id).toList();
    final Map<String, List<LineItemModel>> items =
        await repo.getLineItemsForBills(ids);
    return SpendSummary.from(bills, items);
  }

  void _reload() => setState(_load);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: FutureBuilder<SpendSummary>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _DashboardSkeleton();
            }
            if (snap.hasError) {
              return _ErrorState(onRetry: _reload);
            }
            final summary = snap.data;
            if (summary == null || summary.isEmpty) {
              return const _EmptyState();
            }
            return _DashboardBody(summary: summary, onReload: _reload);
          },
        ),
      ),
    );
  }
}

// ── Body (stateful: holds the selected type for the per-type trend) ─────────
class _DashboardBody extends StatefulWidget {
  const _DashboardBody({required this.summary, required this.onReload});

  final SpendSummary summary;
  final VoidCallback onReload;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  /// The currently tracked bill type, or null for the all-types view.
  String? _selectedType;

  SpendSummary get summary => widget.summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // ── Trend card: all-types line, or a single type's trend when picked ──
    TypeTotal? selected;
    if (_selectedType != null) {
      for (final t in summary.byType) {
        if (t.serviceType == _selectedType) {
          selected = t;
          break;
        }
      }
    }

    final trendMonthly = selected?.monthly ?? summary.monthly;
    final trendTitle =
        selected == null ? 'Spend over time' : '${selected.label} over time';
    final trendTakeaway = selected == null
        ? _timeTakeaway(summary.monthly)
        : _timeTakeaway(selected.monthly);

    final lineCard = SectionCard(
      title: trendTitle,
      takeaway: trendTakeaway,
      semanticSummary: '$trendTitle. $trendTakeaway',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpendLineChart(
            monthly: trendMonthly,
            onSelectMonth: (month) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(_monthLabel(month, trendMonthly)),
                ),
              );
            },
          ),
          if (selected != null) ...[
            const SizedBox(height: AppTokens.space3),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedType = null),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Show all types'),
              ),
            ),
          ],
        ],
      ),
    );

    final typeCard = SectionCard(
      title: 'By bill type',
      takeaway: summary.byType.isEmpty
          ? null
          : (_selectedType == null
              ? 'Tap a type to track just that expense.'
              : 'Tracking ${selected?.label ?? ''}.'),
      semanticSummary: _typeSemantics(summary),
      child: TypeBars(
        types: summary.byType,
        selected: _selectedType,
        onSelect: (t) => setState(
            () => _selectedType = _selectedType == t ? null : t),
      ),
    );

    final providerCard = SectionCard(
      title: 'By provider',
      takeaway: summary.byProvider.isEmpty
          ? null
          : '${summary.byProvider.first.provider} is your largest.',
      semanticSummary: _providerSemantics(summary),
      child: ProviderBars(providers: summary.byProvider),
    );

    final categoryCard = SectionCard(
      title: 'Where it goes',
      takeaway: summary.byCategory.isEmpty
          ? null
          : 'Most of your bill is ${summary.byCategory.first.category.toLowerCase()}.',
      semanticSummary: _categorySemantics(summary),
      child: CategoryDonut(categories: summary.byCategory),
    );

    return RefreshIndicator(
      onRefresh: () async => widget.onReload(),
      child: CenteredContent(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.screenEdge,
            AppTokens.space6,
            AppTokens.screenEdge,
            AppTokens.space8,
          ),
          children: [
            // ── 0. Plain-language headline (leads, not a chart) ──────────
            Semantics(
              header: true,
              child: Text(
                summary.headline,
                style: text.headlineLarge,
              ),
            ),
            const SizedBox(height: AppTokens.space3),
            _VerdictLine(summary: summary),
            const SizedBox(height: AppTokens.space6),

            // ── 1. KPI stats (chunked, responsive) ──────────────────────
            _StatsRow(summary: summary),
            const SizedBox(height: AppTokens.space6),

            // ── 2. Trend (all types, or a single picked type) ───────────
            lineCard,
            const SizedBox(height: AppTokens.space4),

            // ── 3. By bill type (the "track each expense" view) ─────────
            typeCard,
            const SizedBox(height: AppTokens.space4),

            // ── 4 + 5. Provider bars + category donut ───────────────────
            ResponsiveGrid(
              columnsWide: 2,
              children: [providerCard, categoryCard],
            ),
            const SizedBox(height: AppTokens.space6),

            // ── 6. This vs last month (word verdict) ────────────────────
            _ComparisonRow(summary: summary),
          ],
        ),
      ),
    );
  }

  static String _timeTakeaway(List<MonthlyTotal> monthly) {
    if (monthly.length < 2) return 'Your history starts here.';
    final first = monthly.first.total;
    final last = monthly.last.total;
    if (first == 0) return 'Your history starts here.';
    if ((last - first).abs() < first * 0.05) {
      return 'Stayed roughly steady over the year.';
    }
    return last > first
        ? 'Trended up over the year.'
        : 'Trended down over the year.';
  }

  static String _monthLabel(DateTime m, List<MonthlyTotal> monthly) {
    final match = monthly.firstWhere(
      (e) => e.month.year == m.year && e.month.month == m.month,
      orElse: () => monthly.last,
    );
    return 'That month you spent \$${match.total.toStringAsFixed(0)}.';
  }

  static String _typeSemantics(SpendSummary s) {
    if (s.byType.isEmpty) return 'By bill type. No data yet.';
    final parts = s.byType
        .map((t) => '${t.label} \$${t.total.toStringAsFixed(0)}')
        .join(', ');
    return 'By bill type. $parts.';
  }

  static String _providerSemantics(SpendSummary s) {
    if (s.byProvider.isEmpty) return 'By provider. No data yet.';
    final parts = s.byProvider
        .map((p) => '${p.provider} \$${p.total.toStringAsFixed(0)}')
        .join(', ');
    return 'By provider. $parts.';
  }

  static String _categorySemantics(SpendSummary s) {
    if (s.byCategory.isEmpty) return 'Where it goes. No line items yet.';
    final parts = s.byCategory
        .map((c) => '${c.category} \$${c.total.toStringAsFixed(0)}')
        .join(', ');
    return 'Where your money goes. $parts.';
  }
}

// ── KPI stats row (daisyUI *Stat* semantics) ────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});
  final SpendSummary summary;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
    final biggest = summary.byType.isNotEmpty ? summary.byType.first : null;

    return ResponsiveGrid(
      columnsWide: 3,
      gap: AppTokens.space3,
      children: [
        _StatCard(
          title: 'Total spend',
          value: currency.format(summary.total),
          desc: 'over ${summary.monthCount} '
              'month${summary.monthCount == 1 ? '' : 's'}',
          icon: Icons.account_balance_wallet_outlined,
        ),
        _StatCard(
          title: 'Bills tracked',
          value: '${summary.byProvider.length}',
          desc: 'providers',
          icon: Icons.receipt_long_outlined,
        ),
        _StatCard(
          title: 'Biggest type',
          value: biggest?.label ?? '—',
          desc: biggest == null ? '' : currency.format(biggest.total),
          icon: biggest == null
              ? Icons.category_outlined
              : CategoryIcons.iconForKind(CategoryIcons.kindFor(
                  biggest.serviceType,
                  serviceType: biggest.serviceType)),
          accent: biggest == null
              ? null
              : CategoryIcons.colorForKind(CategoryIcons.kindFor(
                  biggest.serviceType,
                  serviceType: biggest.serviceType)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.desc,
    required this.icon,
    this.accent,
  });

  final String title;
  final String value;
  final String desc;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final glyph = accent ?? colours.primary;

    return Semantics(
      label: '$title: $value ${desc.isEmpty ? '' : desc}',
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space4),
        decoration: BoxDecoration(
          color: colours.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTokens.radiusBox),
          border: Border.all(color: colours.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: glyph),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Text(
                    title,
                    style: text.labelMedium
                        ?.copyWith(color: colours.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
              ),
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: AppTokens.space1),
              Text(
                desc,
                style: text.bodySmall
                    ?.copyWith(color: colours.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Verdict line under the headline ─────────────────────────────────────────
class _VerdictLine extends StatelessWidget {
  const _VerdictLine({required this.summary});
  final SpendSummary summary;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Text(
      summary.comparison.hasComparison
          ? 'This month is ${summary.comparison.verdict}.'
          : summary.comparison.verdict,
      style: text.bodyLarge?.copyWith(color: colours.onSurfaceVariant),
    );
  }
}

// ── This vs last month row (words, not color — D2) ──────────────────────────
class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.summary});
  final SpendSummary summary;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final c = summary.comparison;

    return Semantics(
      label: 'This month versus last month: ${c.verdict}.',
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space5),
        decoration: BoxDecoration(
          color: colours.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTokens.radiusBox),
          border: Border.all(color: colours.outline, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.compare_arrows, color: colours.onSurfaceVariant),
            const SizedBox(width: AppTokens.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This month vs last', style: text.titleMedium),
                  const SizedBox(height: AppTokens.space1),
                  Text(
                    c.hasComparison
                        ? 'You are ${c.verdict}.'
                        : c.verdict,
                    style: text.bodyMedium
                        ?.copyWith(color: colours.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty (teaching) state ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined,
                size: 48, color: colours.onSurfaceVariant),
            const SizedBox(height: AppTokens.space5),
            Text(
              'Your spending story starts here',
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space3),
            Text(
              'Add a few bills to see how your spending changes over time.',
              style:
                  text.bodyLarge?.copyWith(color: colours.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space6),
            FilledButton(
              onPressed: () => context.push('/add-bill'),
              child: const Text('Add a bill'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load your spending.',
                style: text.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.space4),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton (loading) ───────────────────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    Widget box(double h, {double w = double.infinity}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: colours.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        );

    return CenteredContent(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.screenEdge, AppTokens.space6,
          AppTokens.screenEdge, AppTokens.space8,
        ),
        children: [
          box(28, w: 280),
          const SizedBox(height: AppTokens.space3),
          box(20, w: 200),
          const SizedBox(height: AppTokens.space6),
          Row(
            children: [
              Expanded(child: box(88)),
              const SizedBox(width: AppTokens.space3),
              Expanded(child: box(88)),
              const SizedBox(width: AppTokens.space3),
              Expanded(child: box(88)),
            ],
          ),
          const SizedBox(height: AppTokens.space6),
          box(260),
          const SizedBox(height: AppTokens.space4),
          box(200),
          const SizedBox(height: AppTokens.space4),
          box(180),
        ],
      ),
    );
  }
}
