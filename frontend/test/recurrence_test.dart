import 'package:flutter_test/flutter_test.dart';
import 'package:bill_intelligence/shared/logic/ics_export.dart';
import 'package:bill_intelligence/shared/logic/recurrence.dart';
import 'package:bill_intelligence/shared/models/repeat_rule.dart';

void main() {
  test('monthly on the 31st clamps in short months', () {
    expect(nextDueDates(DateTime(2026, 1, 31), RepeatEvery.month, DateTime(2026, 1, 31), 3), [
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 31),
      DateTime(2026, 4, 30),
    ]);
  });

  test('yearly Feb 29 falls back to Feb 28', () {
    expect(nextDueAfter(DateTime(2028, 2, 29), RepeatEvery.year, DateTime(2028, 2, 29)),
        DateTime(2029, 2, 28));
  });

  test('weekly and every 3 months', () {
    expect(nextDueDates(DateTime(2026, 9, 25), RepeatEvery.week, DateTime(2026, 9, 25), 2),
        [DateTime(2026, 10, 2), DateTime(2026, 10, 9)]);
    expect(nextDueAfter(DateTime(2026, 1, 15), RepeatEvery.quarter, DateTime(2026, 5, 1)),
        DateTime(2026, 7, 15));
  });

  test('next due is strictly after the cursor', () {
    final a = DateTime(2026, 10, 25);
    expect(nextDueAfter(a, RepeatEvery.month, a), DateTime(2026, 11, 25));
    expect(nextDueAfter(a, RepeatEvery.month, DateTime(2026, 10, 24)), a);
  });

  test('custom every N days', () {
    expect(nextDueDates(DateTime(2026, 9, 25), RepeatEvery.custom, DateTime(2026, 9, 25), 2, days: 21),
        [DateTime(2026, 10, 16), DateTime(2026, 11, 6)]);
    expect(nextDueAfter(DateTime(2026, 2, 1), RepeatEvery.custom, DateTime(2026, 2, 1), days: 30),
        DateTime(2026, 3, 3));
    expect(rruleFor(DateTime(2026, 9, 25), RepeatEvery.custom, days: 30),
        'FREQ=DAILY;INTERVAL=30');
  });

  test('labels', () {
    expect(RepeatEvery.quarter.label, 'Every 3 months');
    expect(RepeatEvery.month.repeatsPhrase(), 'Repeats every month');
    expect(RepeatEvery.custom.repeatsPhrase(21), 'Repeats every 21 days');
    expect(RepeatEvery.custom.repeatsPhrase(1), 'Repeats every day');
  });

  test('ics RRULE and alarm trigger', () {
    expect(rruleFor(DateTime(2026, 1, 30), RepeatEvery.month),
        'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=28,29,30;BYSETPOS=-1');
    expect(rruleFor(DateTime(2026, 1, 15), RepeatEvery.quarter),
        'FREQ=MONTHLY;INTERVAL=3;BYMONTHDAY=15');
    expect(triggerFor(1, 9, 0), '-P0DT15H0M');
    expect(triggerFor(0, 9, 0), 'PT9H0M');
  });
}
