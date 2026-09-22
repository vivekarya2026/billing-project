// home_screen.dart — Bills tab (billing-only)
// --------------------------------------------
// The unified bills view, styled with the daisyUI 5 design system: flat
// base-100 surface, a clean sans title + status headline, a Filter/Tabs-style
// bill-type filter, then the full list of bills as daisyUI list-rows. Each row
// swipes to delete with a 5-second Undo.
//
// UX rules:
//   • Serial-Position: title + status headline lead the viewport.
//   • Hick's Law: the type filter shows only types that exist; "All" first.
//   • Fitts's Law: edge-anchored FAB to add; delete gesture (swipe) is well
//     separated from the row tap target.
//   • Doherty / optimistic UI: delete is applied instantly, reversible via
//     an Undo SnackBar; skeletons (not spinners) cover loading.
//   • Responsive: content is centred and width-capped on laptop/desktop.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/components/bill_list_row.dart';
import '../../../shared/components/bill_type_filter.dart';
import '../../../shared/components/category_icons.dart';
import '../../../shared/data/bill_repository.dart';
import '../../../shared/data/fake_bill_repository.dart';
import '../../../shared/layout/responsive.dart';
import '../../../shared/models/bill.dart';
import '../../../theme/tokens.dart';
import '../../../theme/accents.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Bill>> _billsFuture;

  /// The bills currently held in the list (mutable for optimistic delete).
  List<Bill> _bills = [];
  String _selectedType = kAllBillTypes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<BillRepository>();
    // Full history, newest first — the filter and list operate on everything.
    _billsFuture = repo.getAllBills().then((list) {
      final sorted = [...list]
        ..sort((a, b) => (b.periodEnd ?? b.dueDate ?? DateTime(2000))
            .compareTo(a.periodEnd ?? a.dueDate ?? DateTime(2000)));
      _bills = sorted;
      return sorted;
    });
  }

  void _reload() => setState(() => _load());

  // ── Delete with Undo (optimistic) ──────────────────────────────────────
  Future<void> _deleteBill(Bill bill) async {
    final index = _bills.indexWhere((b) => b.id == bill.id);
    if (index < 0) return;

    setState(() => _bills.removeAt(index));

    final repo = context.read<BillRepository>();
    await repo.deleteBill(bill.id);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Text('Deleted ${bill.provider}.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // Restore in the repo and re-insert at the original position.
            if (repo is FakeBillRepository) {
              FakeBillRepository.restoreBill(bill.id);
            }
            if (!mounted) return;
            setState(() {
              final at = index.clamp(0, _bills.length);
              _bills.insert(at, bill);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text    = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-bill'),
        backgroundColor: colours.primary,
        foregroundColor: colours.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add bill'),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<Bill>>(
          future: _billsFuture,
          builder: (context, snap) {
            // ── Loading → skeleton list (not a spinner) ───────────────
            if (snap.connectionState == ConnectionState.waiting) {
              return const _BillsSkeleton();
            }

            // ── Error ─────────────────────────────────────────────────
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.screenEdge),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Could not load bills.',
                          style: text.bodyLarge, textAlign: TextAlign.center),
                      const SizedBox(height: AppTokens.space4),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ── Empty (no bills at all) → onboarding ──────────────────
            if (_bills.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.go('/onboarding');
              });
              return const SizedBox.shrink();
            }

            return _buildContent(context, text, colours);
          },
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, TextTheme text, ColorScheme colours) {
    // Distinct service types present, ordered by frequency (most first).
    final typeCounts = <String, int>{};
    for (final b in _bills) {
      final t = (b.serviceType).trim().isEmpty ? 'other' : b.serviceType;
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    final types = typeCounts.keys.toList()
      ..sort((a, b) => typeCounts[b]!.compareTo(typeCounts[a]!));
    final chipCounts = <String, int>{kAllBillTypes: _bills.length, ...typeCounts};

    // Apply the active filter.
    final visible = _selectedType == kAllBillTypes
        ? _bills
        : _bills.where((b) {
            final t = (b.serviceType).trim().isEmpty ? 'other' : b.serviceType;
            return t == _selectedType;
          }).toList();

    final statusLine = _statusLine(_bills);

    return RefreshIndicator(
      color: colours.primary,
      backgroundColor: colours.surfaceContainerHighest,
      onRefresh: () async => _reload(),
      child: CenteredContent(
        child: CustomScrollView(
          slivers: [
            // ── Page title ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.screenEdge, AppTokens.space6,
                  AppTokens.screenEdge, 0,
                ),
                child: Text(
                  'Your bills',
                  style: text.headlineLarge,
                ),
              ),
            ),

            // ── Status headline (gradient on key phrase) ─────────────
            SliverToBoxAdapter(
              child: Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.screenEdge, AppTokens.space5,
                    AppTokens.screenEdge, AppTokens.space5,
                  ),
                  child: _StatusHeadline(
                    statusLine: statusLine,
                    textStyle: text.titleLarge,
                  ),
                ),
              ),
            ),

            // ── Bill-type filter ─────────────────────────────────────
            SliverToBoxAdapter(
              child: BillTypeFilter(
                types: types,
                selected: _selectedType,
                counts: chipCounts,
                onSelected: (t) => setState(() => _selectedType = t),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space4)),

            // ── Bills — compact rows, swipe to delete ────────────────
            if (visible.isEmpty)
              SliverToBoxAdapter(child: _EmptyFilter(type: _selectedType))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.screenEdge),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final b = visible[i];
                      final overdue = b.dueDate != null &&
                          b.dueDate!.isBefore(DateTime.now());

                      // Month grouping: show a month header whenever the month
                      // of this row differs from the previous row's month.
                      final thisMonth = _effectiveDate(b);
                      final prevMonth =
                          i > 0 ? _effectiveDate(visible[i - 1]) : null;
                      final isNewMonth = i == 0 ||
                          prevMonth == null ||
                          thisMonth == null ||
                          thisMonth.year != prevMonth.year ||
                          thisMonth.month != prevMonth.month;

                      return Column(
                        children: [
                          // ── Month divider (grouped) ────────────────────
                          if (isNewMonth)
                            _MonthHeader(
                              label: _monthHeaderLabel(thisMonth),
                              first: i == 0,
                            )
                          // ── Thin hairline between rows in the same month ─
                          else
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: colours.outline.withValues(alpha: 0.5),
                            ),
                          Dismissible(
                            key: ValueKey('bill-${b.id}'),
                            direction: DismissDirection.endToStart,
                            background: _DeleteBackground(colours: colours),
                            confirmDismiss: (_) => _confirmDelete(context, b),
                            onDismissed: (_) => _deleteBill(b),
                            child: BillListRow(
                              provider:       b.provider,
                              serviceType:    b.serviceType,
                              amount:         b.amountDue,
                              dueDate:        b.dueDate,
                              isOverdue:      overdue,
                              interpretation: b.narrationSentence ??
                                  'Tap to see details.',
                              onTap: () => context.push('/bill/${b.id}'),
                            ),
                          ),
                        ],
                      );
                    },
                    childCount: visible.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  /// Ask before deleting so a swipe can't destroy data by accident.
  Future<bool> _confirmDelete(BuildContext context, Bill bill) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final text = Theme.of(ctx).textTheme;
        return AlertDialog(
          title: const Text('Delete this bill?'),
          content: Text(
            'Remove ${bill.provider}${bill.amountDue != null ? ' (${NumberFormat.currency(symbol: r'$').format(bill.amountDue)})' : ''}? '
            'You can undo right after.',
            style: text.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep'),
            ),
            // Destructive action visually separated (Fitts / Similarity).
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppAccents.danger,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  String _fmtDue(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff < 0) return 'Overdue by ${-diff} day${-diff == 1 ? '' : 's'}';
    return 'Due ${DateFormat('MMMM d').format(date)}';
  }

  String _statusLine(List<Bill> bills) {
    final now = DateTime.now();
    final overdue = bills.where((b) =>
        b.dueDate != null && b.dueDate!.isBefore(now)).toList();
    if (overdue.isNotEmpty) {
      final n = overdue.length;
      return '$n bill${n > 1 ? 's' : ''} overdue. Check below.';
    }

    final soon = bills.where((b) {
      if (b.dueDate == null) return false;
      final diff = b.dueDate!
          .difference(DateTime(now.year, now.month, now.day)).inDays;
      return diff >= 0 && diff <= 5;
    }).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    if (soon.isNotEmpty) {
      final b = soon.first;
      return '${b.provider} is due ${_fmtDue(b.dueDate).toLowerCase()}.';
    }

    return 'Nothing due soon. Nothing unusual.';
  }

  /// The date a bill is grouped/sorted by (period end, else due date).
  DateTime? _effectiveDate(Bill b) => b.periodEnd ?? b.dueDate;

  /// A month-group header label, e.g. "September 2026" (or "No date").
  String _monthHeaderLabel(DateTime? date) {
    if (date == null) return 'No date';
    return DateFormat('MMMM yyyy').format(date);
  }
}

// ── Month group header (divider between months) ─────────────────────────────
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label, required this.first});
  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        top: first ? AppTokens.space1 : AppTokens.space5,
        bottom: AppTokens.space2,
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: colours.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: colours.outline,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Swipe-to-delete background ──────────────────────────────────────────────
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.colours});
  final ColorScheme colours;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space5),
      decoration: BoxDecoration(
        color: AppAccents.dangerTint,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Delete',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppAccents.danger,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(width: AppTokens.space2),
          const Icon(Icons.delete_outline, color: AppAccents.danger),
        ],
      ),
    );
  }
}

// ── Empty-filter state (a type with no bills) ───────────────────────────────
class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colours = Theme.of(context).colorScheme;
    final label = type == kAllBillTypes
        ? 'bills'
        : '${CategoryIcons.labelForServiceType(type).toLowerCase()} bills';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.screenEdge, AppTokens.space8,
        AppTokens.screenEdge, AppTokens.space8,
      ),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_outlined,
              size: 40, color: colours.onSurfaceVariant),
          const SizedBox(height: AppTokens.space4),
          Text('No $label yet',
              style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppTokens.space2),
          Text('Add one and it will show up here.',
              style: text.bodyMedium
                  ?.copyWith(color: colours.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: AppTokens.space5),
          FilledButton(
            onPressed: () => context.push('/add-bill'),
            child: const Text('Add a bill'),
          ),
        ],
      ),
    );
  }
}

// ── Loading skeleton (rows, matches real layout) ────────────────────────────
class _BillsSkeleton extends StatelessWidget {
  const _BillsSkeleton();

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    Widget box(double h, {double w = double.infinity, double r = 8}) =>
        Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: colours.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(r),
          ),
        );

    Widget row() => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
          child: Row(
            children: [
              box(46, w: 46, r: 12),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(14, w: 140),
                    const SizedBox(height: AppTokens.space2),
                    box(12, w: 200),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              box(18, w: 64),
            ],
          ),
        );

    return CenteredContent(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.screenEdge, AppTokens.space6,
          AppTokens.screenEdge, AppTokens.space8,
        ),
        children: [
          box(30, w: 180),
          const SizedBox(height: AppTokens.space5),
          box(20, w: 240),
          const SizedBox(height: AppTokens.space5),
          box(44, w: 260, r: AppTokens.radiusSelector),
          const SizedBox(height: AppTokens.space5),
          for (var i = 0; i < 6; i++) row(),
        ],
      ),
    );
  }
}

// ── Status headline with optional primary accent word ───────────────────
class _StatusHeadline extends StatelessWidget {
  const _StatusHeadline({
    required this.statusLine,
    this.textStyle,
  });
  final String statusLine;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    // Highlight a keyword in the primary colour (daisyUI text-primary look).
    const accentWords = ['overdue', 'today', 'tomorrow', 'unusual'];
    for (final kw in accentWords) {
      final lower = statusLine.toLowerCase();
      if (lower.contains(kw)) {
        final idx = lower.indexOf(kw);
        final before = statusLine.substring(0, idx);
        final word   = statusLine.substring(idx, idx + kw.length);
        final after  = statusLine.substring(idx + kw.length);

        return Text.rich(
          TextSpan(
            style: textStyle,
            children: [
              TextSpan(text: before),
              TextSpan(
                text: word,
                style: textStyle?.copyWith(
                  color: colours.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: after),
            ],
          ),
        );
      }
    }
    return Text(statusLine, style: textStyle);
  }
}
