// lib/shared/logic/ics_export.dart
// "Add to calendar" for a repeating bill: one all-day VEVENT with an RRULE,
// plus a VALARM matching Settings > Reminders, so the reminder still arrives
// when BillSense is closed.

import 'package:intl/intl.dart';
import '../models/repeat_rule.dart';
import 'recurrence.dart';

String _d(DateTime d) => DateFormat('yyyyMMdd').format(d);

String rruleFor(DateTime anchor, RepeatEvery every, {int days = 0}) {
  final a = dateOnly(anchor);
  switch (every) {
    case RepeatEvery.custom:
      return 'FREQ=DAILY;INTERVAL=${days < 1 ? 1 : days}';
    case RepeatEvery.week:
      const days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      return 'FREQ=WEEKLY;INTERVAL=1;BYDAY=${days[a.weekday - 1]}';
    case RepeatEvery.month:
    case RepeatEvery.quarter:
      final interval = every == RepeatEvery.month ? 1 : 3;
      if (a.day >= 29) {
        final days = [for (var d = 28; d <= a.day; d++) d].join(',');
        return 'FREQ=MONTHLY;INTERVAL=$interval;BYMONTHDAY=$days;BYSETPOS=-1';
      }
      return 'FREQ=MONTHLY;INTERVAL=$interval;BYMONTHDAY=${a.day}';
    case RepeatEvery.year:
      if (a.month == 2 && a.day == 29) {
        return 'FREQ=YEARLY;INTERVAL=1;BYMONTH=2;BYMONTHDAY=28,29;BYSETPOS=-1';
      }
      return 'FREQ=YEARLY;INTERVAL=1;BYMONTH=${a.month};BYMONTHDAY=${a.day}';
  }
}

/// All-day events start at 00:00, so a reminder at hour h, L days before, is
/// -P(L-1)DT(24-h)H; on the day it is +PT(h)H.
String triggerFor(int leadDays, int hour, int minute) {
  if (leadDays == 0) return 'PT${hour}H${minute}M';
  final mins = 24 * 60 - (hour * 60 + minute);
  return '-P${leadDays - 1}DT${mins ~/ 60}H${mins % 60}M';
}

String _escape(String s) =>
    s.replaceAll('\\', '\\\\').replaceAll(';', '\\;').replaceAll(',', '\\,');

String buildIcs({
  required String uid,
  required String name,
  required double? amount,
  required RepeatRule rule,
  required DateTime firstDue,
  int? leadDays,
  int hour = 9,
}) {
  final stamp = '${DateFormat("yyyyMMdd'T'HHmmss").format(DateTime.now().toUtc())}Z';
  final start = dateOnly(firstDue);
  final money = amount == null
      ? ''
      : '${NumberFormat.currency(symbol: r'$').format(amount)}. ';
  final b = StringBuffer()
    ..writeln('BEGIN:VCALENDAR')
    ..writeln('VERSION:2.0')
    ..writeln('PRODID:-//BillSense//Bills//EN')
    ..writeln('CALSCALE:GREGORIAN')
    ..writeln('BEGIN:VEVENT')
    ..writeln('UID:$uid@billsense')
    ..writeln('DTSTAMP:$stamp')
    ..writeln('DTSTART;VALUE=DATE:${_d(start)}')
    ..writeln('DTEND;VALUE=DATE:${_d(start.add(const Duration(days: 1)))}')
    ..writeln('RRULE:${rruleFor(rule.anchor, rule.every, days: rule.days)}')
    ..writeln('SUMMARY:${_escape('Pay $name')}')
    ..writeln('DESCRIPTION:${_escape('$money${rule.phrase}.')}');
  if (leadDays != null) {
    b
      ..writeln('BEGIN:VALARM')
      ..writeln('ACTION:DISPLAY')
      ..writeln('DESCRIPTION:${_escape('Pay $name')}')
      ..writeln('TRIGGER:${triggerFor(leadDays, hour, 0)}')
      ..writeln('END:VALARM');
  }
  b
    ..writeln('END:VEVENT')
    ..writeln('END:VCALENDAR');
  return b.toString().replaceAll('\n', '\r\n');
}
