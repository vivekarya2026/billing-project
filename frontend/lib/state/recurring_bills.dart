// lib/state/recurring_bills.dart
// Repeating manual bills (docs/design/payment-reminders/07-redesign.md).
//
// Every cycle is a real Bill, so the Bills list, detail, edit, delete and the
// status line need no special cases. For each rule this keeps at most one
// unpaid bill, and issues the next cycle once there is none. Deleting a cycle
// skips it. Also sends the Settings > Reminders browser notifications.
//
// Rules live for the session, like manually added bills in demo mode.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../shared/data/bill_repository.dart';
import '../shared/data/fake_bill_repository.dart';
import '../shared/logic/recurrence.dart';
import '../shared/models/bill.dart';
import '../shared/models/repeat_rule.dart';
import '../shared/platform/browser_bridge.dart';
import 'settings_state.dart';

const _notifiedKey = 'reminder_notified_v1';
const reminderHour = 9;

class RecurringBills extends ChangeNotifier {
  RecurringBills._();
  static final RecurringBills instance = RecurringBills._();

  final _uuid = const Uuid();
  BillRepository? _repo;
  final Map<String, RepeatRule> _rules = {};

  // Per rule: bill id → due date, as last seen. A bill that disappears
  // without being in _selfRemoved was deleted by the user.
  final Map<String, Map<String, DateTime>> _seen = {};
  final Set<String> _selfRemoved = {};

  bool _running = false;
  bool _again = false;
  Timer? _ticker;

  /// Set by the app shell so a notification click opens the bill.
  void Function(String billId)? onOpenBill;

  static bool isRepeatAccount(String accountId) => accountId.startsWith('rep-');

  String newAccountId() => 'rep-${_uuid.v4()}';

  RepeatRule? ruleFor(String accountId) => _rules[accountId];

  /// The cycle after [due], for "Next one is due …" copy.
  DateTime? nextAfter(String accountId, DateTime due) {
    final r = _rules[accountId];
    return r == null ? null : nextDueAfter(r.anchor, r.every, due, days: r.days);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  Future<void> init(BillRepository repo) async {
    if (_repo != null) return;
    _repo = repo;
    await _seed();
    FakeBillRepository.revision.addListener(_onBillsChanged);
    await _reconcile();
    _ticker = Timer.periodic(const Duration(minutes: 5), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    FakeBillRepository.revision.removeListener(_onBillsChanged);
    super.dispose();
  }

  void _onBillsChanged() => unawaited(_reconcile());

  /// Demo data: rent monthly with last month paid, car insurance yearly.
  Future<void> _seed() async {
    final today = dateOnly(DateTime.now());
    final rentDue = today.add(const Duration(days: 3));
    final rentPrev = DateTime(rentDue.year, rentDue.month - 1,
        rentDue.day.clamp(1, lastDayOf(rentDue.year, rentDue.month - 1)));
    final carDue = today.add(const Duration(days: 10));
    const rentAcc = 'rep-seed-rent';
    const carAcc = 'rep-seed-car';

    final paidId = await _create(
      accountId: rentAcc, provider: 'Rent', serviceType: 'rent',
      amount: 1450, due: rentPrev,
    );
    await _repo!.updateBill(paidId, {'is_paid': true});
    await _create(
      accountId: rentAcc, provider: 'Rent', serviceType: 'rent',
      amount: 1450, due: rentDue,
    );
    await _create(
      accountId: carAcc, provider: 'Car insurance', serviceType: 'insurance',
      amount: 640, due: carDue,
    );
    _rules[rentAcc] = RepeatRule(
        accountId: rentAcc, every: RepeatEvery.month,
        anchor: rentDue, lastIssued: rentDue);
    _rules[carAcc] = RepeatRule(
        accountId: carAcc, every: RepeatEvery.year,
        anchor: carDue, lastIssued: carDue);
  }

  // ── Writes from the manual bill form ──────────────────────────────────

  /// Starts or changes the rule for [accountId], anchored on [billId]'s due
  /// date. Other unpaid cycles are removed so the next one follows the new
  /// rule.
  Future<void> setRule({
    required String accountId,
    required String billId,
    required RepeatEvery every,
    required DateTime due,
    int days = 0,
  }) async {
    final d = dateOnly(due);
    _rules[accountId] = RepeatRule(
        accountId: accountId, every: every, anchor: d, lastIssued: d,
        days: days);
    final bills = await _repo!.getAllBills();
    for (final b in bills) {
      if (b.accountId == accountId && b.id != billId && !b.isPaid) {
        _selfRemoved.add(b.id);
        await _repo!.deleteBill(b.id);
      }
    }
    notifyListeners();
    await _reconcile();
  }

  /// "Doesn't repeat": existing bills stay, no more are issued.
  void removeRule(String accountId) {
    _rules.remove(accountId);
    _seen.remove(accountId);
    notifyListeners();
  }

  // ── Engine ────────────────────────────────────────────────────────────

  Future<void> _reconcile() async {
    final repo = _repo;
    if (repo == null) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        final all = await repo.getAllBills();
        for (final rule in _rules.values.toList()) {
          await _reconcileRule(rule, all);
        }
      } while (_again);
    } finally {
      _running = false;
    }
    notifyListeners();
  }

  Future<void> _reconcileRule(RepeatRule rule, List<Bill> all) async {
    final mine = all.where((b) => b.accountId == rule.accountId).toList();
    final seen = _seen.putIfAbsent(rule.accountId, () => {});
    final ids = {for (final b in mine) b.id};
    for (final id in seen.keys.toList()) {
      if (ids.contains(id)) continue;
      final due = seen.remove(id)!;
      if (!_selfRemoved.remove(id) && due.isAfter(rule.lastIssued)) {
        rule.lastIssued = due;
      }
    }
    for (final b in mine) {
      if (b.dueDate != null) seen[b.id] = dateOnly(b.dueDate!);
    }

    final unpaid = mine.where((b) => !b.isPaid && b.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    if (unpaid.length > 1) {
      for (final extra in unpaid.skip(1)) {
        _selfRemoved.add(extra.id);
        await _repo!.deleteBill(extra.id);
      }
      return;
    }
    if (unpaid.isNotEmpty) return;

    var cursor = rule.lastIssued;
    Bill? template;
    for (final b in mine) {
      if (b.dueDate == null) continue;
      final d = dateOnly(b.dueDate!);
      if (d.isAfter(cursor)) cursor = d;
      if (template == null || b.dueDate!.isAfter(template.dueDate!)) {
        template = b;
      }
    }
    if (template == null) return;

    // After time away, issue only the most recent missed cycle.
    final today = dateOnly(DateTime.now());
    var next = nextDueAfter(rule.anchor, rule.every, cursor, days: rule.days);
    while (true) {
      final after = nextDueAfter(rule.anchor, rule.every, next, days: rule.days);
      if (after.isAfter(today)) break;
      next = after;
    }
    rule.lastIssued = next;
    await _create(
      accountId: rule.accountId,
      provider: template.provider,
      serviceType: template.serviceType,
      amount: template.amountDue,
      due: next,
    );
  }

  Future<String> _create({
    required String accountId,
    required String provider,
    required String serviceType,
    required double? amount,
    required DateTime due,
  }) async {
    final id = _uuid.v4();
    final today = dateOnly(DateTime.now());
    String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
    await _repo!.createBill({
      'id': id,
      'account_id': accountId,
      'provider': provider,
      'name': provider,
      'service_type': serviceType,
      'amount_due': amount,
      'due_date': iso(due),
      'period_end': iso(due.isBefore(today) ? due : today),
      'extraction_status': 'done',
      'narration_sentence': 'Same amount as last time. Added for you.',
    });
    return id;
  }

  // ── Reminders (Settings > Reminders, while a tab is open) ─────────────

  Future<void> _tick() async {
    final mode = SettingsState.instance.reminders;
    if (mode == 'off' || _repo == null) return;
    if (notificationPermission() != 'granted' || !isPageHidden()) return;

    final now = DateTime.now();
    if (now.hour < reminderHour) return;
    final today = dateOnly(now);
    final lead = mode == 'day_before' ? 1 : 0;
    final prefs = await SharedPreferences.getInstance();
    final sent = prefs.getStringList(_notifiedKey) ?? <String>[];
    final money = NumberFormat.currency(symbol: r'$');

    var shown = 0;
    for (final b in await _repo!.getAllBills()) {
      if (b.isPaid || b.dueDate == null || shown >= 3) continue;
      final due = dateOnly(b.dueDate!);
      if (due.subtract(Duration(days: lead)) != today) continue;
      final key = '${b.provider}|${DateFormat('yyyy-MM-dd').format(due)}';
      if (sent.contains(key)) continue;
      final amount = b.amountDue == null ? '' : ': ${money.format(b.amountDue)}';
      final when = lead == 1
          ? 'due tomorrow, ${DateFormat('MMM d').format(due)}'
          : 'due today';
      showBrowserNotification(
        title: b.provider,
        body: '${b.provider}$amount $when.',
        tag: key,
        onClick: () => onOpenBill?.call(b.id),
      );
      sent.add(key);
      shown++;
    }
    if (shown > 0) {
      await prefs.setStringList(
          _notifiedKey, sent.length > 50 ? sent.sublist(sent.length - 50) : sent);
    }
  }
}
