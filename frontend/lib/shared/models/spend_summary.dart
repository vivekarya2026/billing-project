// lib/shared/models/spend_summary.dart
// -------------------------------------
// Client-side view-model for the Spend dashboard. Computed from a list
// of bills (full history) + their line items. Holds only plain numbers
// and words — no widgets, no colors. The dashboard renders it.
//
// Honors D2: comparisons are expressed as WORDS ("about the same",
// "up $23"), never as red/green semantics. Callers turn these into
// muted, word-labeled visuals.

import 'bill.dart';
import 'line_item.dart';

/// One month's total across all providers.
class MonthlyTotal {
  const MonthlyTotal(this.month, this.total);

  /// First day of the month this total covers.
  final DateTime month;
  final double total;
}

/// One provider's total across the whole window.
class ProviderTotal {
  const ProviderTotal(this.provider, this.serviceType, this.total);
  final String provider;
  final String serviceType;
  final double total;
}

/// One bill type's (service type) total across the window, plus its own
/// monthly series so a per-type trend can be drawn.
class TypeTotal {
  const TypeTotal({
    required this.serviceType,
    required this.label,
    required this.total,
    required this.monthly,
  });
  final String serviceType;
  final String label;
  final double total;
  final List<MonthlyTotal> monthly; // chronological
}

/// One charge category's total (distribution / generation / tax / fee …).
class CategoryTotal {
  const CategoryTotal(this.category, this.total);
  final String category;
  final double total;
}

/// The month-over-month comparison, expressed in words (D2).
class MonthComparison {
  const MonthComparison({
    required this.hasComparison,
    required this.delta,
    required this.verdict,
  });

  /// True when there are at least two months to compare.
  final bool hasComparison;

  /// Signed dollar change vs the previous month (latest − previous).
  final double delta;

  /// A calm, plain-language verdict. Never a color.
  /// e.g. "about the same", "up $23", "down $18".
  final String verdict;
}

class SpendSummary {
  const SpendSummary({
    required this.monthly,
    required this.byProvider,
    required this.byType,
    required this.byCategory,
    required this.comparison,
    required this.total,
    required this.providerCount,
    required this.monthCount,
  });

  final List<MonthlyTotal> monthly;   // chronological
  final List<ProviderTotal> byProvider; // ranked, high → low
  final List<TypeTotal> byType;        // ranked, high → low
  final List<CategoryTotal> byCategory;  // ranked, high → low
  final MonthComparison comparison;
  final double total;
  final int providerCount;
  final int monthCount;

  bool get isEmpty => monthly.isEmpty;

  /// A plain-language headline that leads the dashboard (not a chart).
  /// e.g. "You've spent $1,240 across 2 providers over 12 months."
  String get headline {
    if (isEmpty) {
      return 'Add a few bills to see your spending story.';
    }
    final amount = _money(total);
    final providers =
        '$providerCount provider${providerCount == 1 ? '' : 's'}';
    final months = '$monthCount month${monthCount == 1 ? '' : 's'}';
    return "You've spent $amount across $providers over $months.";
  }

  // ── Builder ──────────────────────────────────────────────────────────
  /// Builds a summary from bills + a bill-id → line-items map.
  /// Bills without an [amountDue] are ignored for totals.
  factory SpendSummary.from(
    List<Bill> bills,
    Map<String, List<LineItemModel>> lineItemsByBill,
  ) {
    // ── Monthly totals (keyed by period_end month, fallback due_date) ──
    final monthlyMap = <DateTime, double>{};
    for (final b in bills) {
      final amount = b.amountDue;
      if (amount == null) continue;
      final anchor = b.periodEnd ?? b.dueDate;
      if (anchor == null) continue;
      final key = DateTime(anchor.year, anchor.month);
      monthlyMap[key] = (monthlyMap[key] ?? 0) + amount;
    }
    final monthly = monthlyMap.entries
        .map((e) => MonthlyTotal(e.key, e.value))
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    // ── Per-provider totals ────────────────────────────────────────────
    final providerMap = <String, double>{};
    final providerService = <String, String>{};
    for (final b in bills) {
      final amount = b.amountDue;
      if (amount == null) continue;
      providerMap[b.provider] = (providerMap[b.provider] ?? 0) + amount;
      providerService[b.provider] = b.serviceType;
    }
    final byProvider = providerMap.entries
        .map((e) =>
            ProviderTotal(e.key, providerService[e.key] ?? '', e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    // ── Per-type totals + per-type monthly series ──────────────────────
    // Group bills by serviceType; keep each type's own monthly series so the
    // Insights screen can draw a trend for a single type.
    final typeTotal = <String, double>{};
    final typeMonthly = <String, Map<DateTime, double>>{};
    for (final b in bills) {
      final amount = b.amountDue;
      if (amount == null) continue;
      final t = (b.serviceType).trim().isEmpty ? 'other' : b.serviceType;
      typeTotal[t] = (typeTotal[t] ?? 0) + amount;
      final anchor = b.periodEnd ?? b.dueDate;
      if (anchor != null) {
        final key = DateTime(anchor.year, anchor.month);
        final m = typeMonthly.putIfAbsent(t, () => <DateTime, double>{});
        m[key] = (m[key] ?? 0) + amount;
      }
    }
    final byType = typeTotal.entries.map((e) {
      final monthlyList = (typeMonthly[e.key] ?? {})
          .entries
          .map((m) => MonthlyTotal(m.key, m.value))
          .toList()
        ..sort((a, b) => a.month.compareTo(b.month));
      return TypeTotal(
        serviceType: e.key,
        label: _typeLabel(e.key),
        total: e.value,
        monthly: monthlyList,
      );
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    // ── Per-category totals (from line items) ──────────────────────────
    final categoryMap = <String, double>{};
    for (final items in lineItemsByBill.values) {
      for (final li in items) {
        // Credits reduce; charges/taxes/fees add.
        final signed = li.itemType == 'credit' ? -li.amount : li.amount;
        final label = _categoryLabel(li.itemType);
        categoryMap[label] = (categoryMap[label] ?? 0) + signed;
      }
    }
    final byCategory = categoryMap.entries
        .where((e) => e.value.abs() > 0.005)
        .map((e) => CategoryTotal(e.key, e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    // ── Month-over-month comparison (words, not color) ─────────────────
    MonthComparison comparison;
    if (monthly.length < 2) {
      comparison = const MonthComparison(
        hasComparison: false,
        delta: 0,
        verdict: 'Not enough history yet.',
      );
    } else {
      final latest = monthly[monthly.length - 1].total;
      final prev = monthly[monthly.length - 2].total;
      final delta = latest - prev;
      comparison = MonthComparison(
        hasComparison: true,
        delta: delta,
        verdict: _verdict(delta, prev),
      );
    }

    final total =
        monthly.fold<double>(0, (sum, m) => sum + m.total);

    return SpendSummary(
      monthly: monthly,
      byProvider: byProvider,
      byType: byType,
      byCategory: byCategory,
      comparison: comparison,
      total: total,
      providerCount: providerMap.length,
      monthCount: monthly.length,
    );
  }

  // ── Word helpers (D2) ──────────────────────────────────────────────────
  static String _verdict(double delta, double prev) {
    final abs = delta.abs();
    // Within 5% (or under $5) of last month = "about the same".
    final threshold = (prev * 0.05).clamp(5.0, double.infinity);
    if (abs < threshold) return 'about the same as last month';
    final direction = delta > 0 ? 'up' : 'down';
    return '$direction ${_money(abs)} from last month';
  }

  static String _typeLabel(String serviceType) {
    switch (serviceType.toLowerCase().trim()) {
      case 'electric':
      case 'electricity':
        return 'Electric';
      case 'gas':
        return 'Gas';
      case 'water':
      case 'sewer':
        return 'Water';
      case 'internet':
      case 'wifi':
      case 'broadband':
        return 'Internet';
      case 'trash':
      case 'waste':
        return 'Trash';
      case 'phone':
      case 'mobile':
        return 'Phone';
      case 'streaming':
      case 'subscription':
        return 'Streaming';
      case 'insurance':
        return 'Insurance';
      case 'rent':
        return 'Rent';
      case 'cable':
      case 'tv':
        return 'Cable';
      case 'other':
      case '':
        return 'Other';
      default:
        return serviceType[0].toUpperCase() + serviceType.substring(1);
    }
  }

  static String _categoryLabel(String itemType) {
    switch (itemType) {
      case 'charge':
        return 'Charges';
      case 'tax':
        return 'Taxes';
      case 'fee':
        return 'Fees';
      case 'credit':
        return 'Credits';
      default:
        return 'Other';
    }
  }

  static String _money(double v) {
    // Simple, dependency-free currency formatting for headlines/verdicts.
    final neg = v < 0;
    final n = v.abs();
    final whole = n.round();
    final s = whole.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${neg ? '-' : ''}\$$buf';
  }
}
