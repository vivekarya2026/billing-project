// lib/shared/logic/recurrence.dart
// Pure date maths for repeating bills. Monthly dates past the 28th clamp to
// the last day of shorter months; Feb 29 falls back to Feb 28.

import '../models/repeat_rule.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int lastDayOf(int year, int month) => DateTime(year, month + 1, 0).day;

/// The n-th due date counted from [anchor] (n = 0 is the anchor itself).
DateTime nthDue(DateTime anchor, RepeatEvery every, int n, {int days = 0}) {
  final a = dateOnly(anchor);
  switch (every) {
    case RepeatEvery.week:
      return DateTime(a.year, a.month, a.day + 7 * n);
    case RepeatEvery.custom:
      return DateTime(a.year, a.month, a.day + (days < 1 ? 1 : days) * n);
    case RepeatEvery.month:
    case RepeatEvery.quarter:
      final step = every == RepeatEvery.month ? 1 : 3;
      final total = a.month - 1 + step * n;
      final y = a.year + total ~/ 12;
      final m = total % 12 + 1;
      final last = lastDayOf(y, m);
      return DateTime(y, m, a.day > last ? last : a.day);
    case RepeatEvery.year:
      final y = a.year + n;
      final last = lastDayOf(y, a.month);
      return DateTime(y, a.month, a.day > last ? last : a.day);
  }
}

/// First due date strictly after [after].
DateTime nextDueAfter(DateTime anchor, RepeatEvery every, DateTime after,
    {int days = 0}) {
  final cursor = dateOnly(after);
  var n = 0;
  while (!nthDue(anchor, every, n, days: days).isAfter(cursor)) {
    n++;
  }
  return nthDue(anchor, every, n, days: days);
}

/// The next [count] due dates strictly after [after].
List<DateTime> nextDueDates(
    DateTime anchor, RepeatEvery every, DateTime after, int count,
    {int days = 0}) {
  final out = <DateTime>[];
  var cursor = after;
  while (out.length < count) {
    cursor = nextDueAfter(anchor, every, cursor, days: days);
    out.add(cursor);
  }
  return out;
}
