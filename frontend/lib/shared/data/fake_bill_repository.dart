// lib/shared/data/fake_bill_repository.dart
// -------------------------------------------
// In-memory repository used when BYPASS_AUTH=true and Supabase is
// not available (dev / CI). Data mirrors backend/supabase/seed.sql
// so the UI looks identical to production.
//
// Switch: in main.dart, set useReal=false to use this.

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/bill.dart';
import '../models/property.dart';
import '../models/account.dart';
import '../models/extraction_field.dart';
import '../models/line_item.dart';
import 'bill_repository.dart';

class FakeBillRepository implements BillRepository {
  // ── In-memory store for user-added bills (manual entry / capture) ──────
  // These are session-only: they disappear on reload, which is acceptable
  // for the offline demo. Newest first.
  static final List<Bill> _userBills = [];
  static final Map<String, String> _narrationOverrides = {};

  /// Bumped whenever the bill set changes (create / update / delete / restore)
  /// so live screens (e.g. the Bills list) can reload themselves even while
  /// kept alive by the shell's IndexedStack.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static void _bump() => revision.value++;

  // Soft-delete + edit overrides (M15). Deleted ids are filtered out of every
  // read so the Bills list can offer an Undo (re-add by clearing the id).
  // Edits are shallow field overrides applied on top of seed/user bills.
  static final Set<String> _deletedIds = {};
  static final Map<String, Map<String, dynamic>> _edits = {};

  // ── Seed data ──────────────────────────────────────────────────────────

  static final _property = Property(
    id: '10000000-0000-0000-0000-000000000001',
    userId: '00000000-0000-0000-0000-000000000001',
    name: 'Main home',
    address: '221 Elm Street, Columbus OH 43205',
    createdAt: DateTime(2023, 1, 1),
  );

  static const _accounts = [
    Account(
      id: '20000000-0000-0000-0000-000000000001',
      userId: '00000000-0000-0000-0000-000000000001',
      propertyId: '10000000-0000-0000-0000-000000000001',
      provider: 'Ohio Edison',
      accountNumber: '****-4892',
      serviceType: 'electric',
      isActive: true,
    ),
    Account(
      id: '20000000-0000-0000-0000-000000000002',
      userId: '00000000-0000-0000-0000-000000000001',
      propertyId: '10000000-0000-0000-0000-000000000001',
      provider: 'Columbia Gas',
      accountNumber: '****-7741',
      serviceType: 'gas',
      isActive: true,
    ),
    Account(
      id: '20000000-0000-0000-0000-000000000003',
      userId: '00000000-0000-0000-0000-000000000001',
      propertyId: '10000000-0000-0000-0000-000000000001',
      provider: 'City Water Dept',
      accountNumber: '****-3310',
      serviceType: 'water',
      isActive: true,
    ),
    Account(
      id: '20000000-0000-0000-0000-000000000004',
      userId: '00000000-0000-0000-0000-000000000001',
      propertyId: '10000000-0000-0000-0000-000000000001',
      provider: 'Spectrum Internet',
      accountNumber: '****-2288',
      serviceType: 'internet',
      isActive: true,
    ),
    Account(
      id: '20000000-0000-0000-0000-000000000005',
      userId: '00000000-0000-0000-0000-000000000001',
      propertyId: '10000000-0000-0000-0000-000000000001',
      provider: 'Verizon Wireless',
      accountNumber: '****-9075',
      serviceType: 'phone',
      isActive: true,
    ),
    Account(
      id: '20000000-0000-0000-0000-000000000006',
      userId: '00000000-0000-0000-0000-000000000001',
      propertyId: '10000000-0000-0000-0000-000000000001',
      provider: 'Netflix',
      accountNumber: '****-0001',
      serviceType: 'streaming',
      isActive: true,
    ),
  ];

  // ── 12 months × 6 providers ────────────────────────────────────────────
  // Generated so the dashboard renders a full, real-looking history offline.
  // Electric/gas peak in winter; water/internet/phone/streaming are steadier.
  // Amounts mirror the seasonal shape used in seed.sql.

  static const _electricAccount  = '20000000-0000-0000-0000-000000000001';
  static const _gasAccount       = '20000000-0000-0000-0000-000000000002';
  static const _waterAccount     = '20000000-0000-0000-0000-000000000003';
  static const _internetAccount  = '20000000-0000-0000-0000-000000000004';
  static const _phoneAccount     = '20000000-0000-0000-0000-000000000005';
  static const _streamingAccount = '20000000-0000-0000-0000-000000000006';

  // period_end month (2024-03 … 2025-02) → amount for each provider.
  static const _electricByMonth = <double>[
    138.20, 121.40, 118.90, 132.60, 158.30, 149.70, // Mar–Aug 2024
    134.10, 143.20, 181.60, 199.40, 204.80, 176.40, // Sep 2024–Feb 2025
  ];
  static const _gasByMonth = <double>[
    88.40, 61.20, 42.10, 33.80, 31.50, 34.90, // Mar–Aug 2024
    58.70, 82.30, 101.40, 112.60, 118.70, 94.20, // Sep 2024–Feb 2025
  ];
  // Water drifts up gently in summer (irrigation), otherwise steady.
  static const _waterByMonth = <double>[
    42.10, 44.30, 48.90, 56.40, 61.20, 58.70, // Mar–Aug 2024
    49.80, 45.30, 43.10, 44.60, 46.20, 45.10, // Sep 2024–Feb 2025
  ];
  // Internet — flat plan with one small mid-year price bump.
  static const _internetByMonth = <double>[
    69.99, 69.99, 69.99, 74.99, 74.99, 74.99, // Mar–Aug 2024
    74.99, 74.99, 74.99, 74.99, 74.99, 74.99, // Sep 2024–Feb 2025
  ];
  // Phone — mostly flat with occasional overage.
  static const _phoneByMonth = <double>[
    85.00, 85.00, 92.40, 85.00, 85.00, 98.10, // Mar–Aug 2024
    85.00, 85.00, 85.00, 90.20, 85.00, 85.00, // Sep 2024–Feb 2025
  ];
  // Streaming — flat subscription with one plan increase.
  static const _streamingByMonth = <double>[
    15.49, 15.49, 15.49, 15.49, 15.49, 15.49, // Mar–Aug 2024
    22.99, 22.99, 22.99, 22.99, 22.99, 22.99, // Sep 2024–Feb 2025
  ];

  static List<Bill> _generateBills() {
    final bills = <Bill>[];
    // Anchor the 12-month window so the newest bill's period ends last month
    // (relative to today). This keeps the demo current no matter the date.
    final now = DateTime.now();
    final anchorMonth = DateTime(now.year, now.month, 1); // first of this month

    // Each tracked service: (account, provider, serviceType, series, id-seg,
    // due-offset days, narration noun).
    final services = <_SeedService>[
      _SeedService(_electricAccount,  'Ohio Edison',       'electric',  _electricByMonth,  '0001', 20, 'electricity'),
      _SeedService(_gasAccount,       'Columbia Gas',      'gas',       _gasByMonth,       '0002', 13, 'gas'),
      _SeedService(_waterAccount,     'City Water Dept',   'water',     _waterByMonth,     '0003', 18, 'water'),
      _SeedService(_internetAccount,  'Spectrum Internet', 'internet',  _internetByMonth,  '0004', 10, 'internet'),
      _SeedService(_phoneAccount,     'Verizon Wireless',  'phone',     _phoneByMonth,     '0005', 15, 'phone'),
      _SeedService(_streamingAccount, 'Netflix',           'streaming', _streamingByMonth, '0006',  7, 'streaming'),
    ];

    // Month index 0 = 11 months ago … 11 = the CURRENT cycle.
    // The newest cycle (i == 11) is dated a few days in the FUTURE so it reads
    // as "due in N days" (upcoming), not overdue. Older cycles are historical
    // records and are flagged as already paid (no overdue alarm).
    for (var i = 0; i < 12; i++) {
      final monthsAgo = 11 - i; // 11 … 0
      final isCurrent = i == 11;

      final DateTime periodEnd;
      final DateTime dueBase;
      if (isCurrent) {
        // Current cycle ends now; due dates land a bit in the future.
        periodEnd = DateTime(now.year, now.month, now.day);
        dueBase = DateTime(now.year, now.month, now.day);
      } else {
        final periodEndMonth =
            DateTime(anchorMonth.year, anchorMonth.month - monthsAgo, 1);
        periodEnd = DateTime(periodEndMonth.year, periodEndMonth.month, 26);
        dueBase = periodEnd;
      }
      final periodStart = DateTime(periodEnd.year, periodEnd.month, 1)
          .subtract(const Duration(days: 5));
      final seq = (i + 1).toString().padLeft(2, '0');

      for (final s in services) {
        // Current cycle: due a few days out (offset % 10 + 2 days ahead).
        // Historical cycles: due in the past but marked paid.
        final due = isCurrent
            ? dueBase.add(Duration(days: (s.dueOffset % 10) + 2))
            : dueBase.add(Duration(days: s.dueOffset));
        bills.add(Bill(
          id: 'b0000000-0000-0000-${s.idSeg}-0000000000$seq',
          accountId: s.account,
          provider: s.provider,
          serviceType: s.serviceType,
          amountDue: s.series[i],
          dueDate: due,
          periodStart: periodStart,
          periodEnd: periodEnd,
          extractionStatus: 'done',
          isPaid: !isCurrent,
          narrationSentence: _narration(i, s.series, s.noun),
        ));
      }
    }
    // Newest first (home screen expects most-recent-per-provider).
    bills.sort((a, b) =>
        (b.periodEnd ?? DateTime(2000)).compareTo(a.periodEnd ?? DateTime(2000)));
    return bills;
  }

  static String _narration(int i, List<double> series, String kind) {
    if (i == 0) return 'Your first tracked $kind bill.';
    final delta = series[i] - series[i - 1];
    final abs = delta.abs();
    if (abs < 5) return 'About the same as last month. Normal.';
    final dir = delta > 0 ? 'Up' : 'Down';
    return '$dir \$${abs.toStringAsFixed(2)} from last month.';
  }

  static final List<Bill> _bills = _generateBills();

  // The most recent electric bill still carries rich detail data.
  static const _detailBillId = 'b0000000-0000-0000-0001-000000000012';

  static const _lineItemsFeb25Electric = [
    LineItemModel(id: 'li1', billId: _detailBillId,
        description: 'Distribution charge', amount: 46.20, itemType: 'charge', sortOrder: 0),
    LineItemModel(id: 'li2', billId: _detailBillId,
        description: 'Generation charge', amount: 89.30, itemType: 'charge', sortOrder: 1),
    LineItemModel(id: 'li3', billId: _detailBillId,
        description: 'Transmission charge', amount: 22.10, itemType: 'charge', sortOrder: 2),
    LineItemModel(id: 'li4', billId: _detailBillId,
        description: 'State taxes and fees', amount: 12.80, itemType: 'tax', sortOrder: 3),
    LineItemModel(id: 'li5', billId: _detailBillId,
        description: 'Renewable energy rider', amount: 6.00, itemType: 'fee', sortOrder: 4),
  ];

  // Synthesize plausible line items for every bill so the category
  // donut has full-history data. Split each total into the same
  // proportional buckets used on a real utility bill.
  static Map<String, List<LineItemModel>> _generateLineItems() {
    final map = <String, List<LineItemModel>>{};
    for (final b in _bills) {
      final total = b.amountDue ?? 0;
      if (b.id == _detailBillId) {
        map[b.id] = _lineItemsFeb25Electric;
        continue;
      }
      final isElectric = b.serviceType == 'electric';
      final isGas = b.serviceType == 'gas';
      // Distribution ~26%, Generation ~51%, Transmission ~12%,
      // Tax ~7%, Fee ~4% (electric). Gas: Delivery/Supply/Tax/Fee.
      // Water/internet/phone/streaming: a simpler service + tax/fee split.
      final items = <LineItemModel>[];
      if (isElectric) {
        items.addAll([
          LineItemModel(id: '${b.id}-c1', billId: b.id,
              description: 'Distribution charge',
              amount: _r(total * 0.26), itemType: 'charge', sortOrder: 0),
          LineItemModel(id: '${b.id}-c2', billId: b.id,
              description: 'Generation charge',
              amount: _r(total * 0.51), itemType: 'charge', sortOrder: 1),
          LineItemModel(id: '${b.id}-c3', billId: b.id,
              description: 'Transmission charge',
              amount: _r(total * 0.12), itemType: 'charge', sortOrder: 2),
          LineItemModel(id: '${b.id}-t1', billId: b.id,
              description: 'State taxes and fees',
              amount: _r(total * 0.07), itemType: 'tax', sortOrder: 3),
          LineItemModel(id: '${b.id}-f1', billId: b.id,
              description: 'Renewable energy rider',
              amount: _r(total * 0.04), itemType: 'fee', sortOrder: 4),
        ]);
      } else if (isGas) {
        items.addAll([
          LineItemModel(id: '${b.id}-c1', billId: b.id,
              description: 'Delivery charge',
              amount: _r(total * 0.40), itemType: 'charge', sortOrder: 0),
          LineItemModel(id: '${b.id}-c2', billId: b.id,
              description: 'Gas supply charge',
              amount: _r(total * 0.49), itemType: 'charge', sortOrder: 1),
          LineItemModel(id: '${b.id}-t1', billId: b.id,
              description: 'State taxes',
              amount: _r(total * 0.07), itemType: 'tax', sortOrder: 2),
          LineItemModel(id: '${b.id}-f1', billId: b.id,
              description: 'Service fee',
              amount: _r(total * 0.04), itemType: 'fee', sortOrder: 3),
        ]);
      } else {
        // Water / internet / phone / streaming: one service charge, small tax.
        final label = _serviceChargeLabel(b.serviceType);
        items.addAll([
          LineItemModel(id: '${b.id}-c1', billId: b.id,
              description: label,
              amount: _r(total * 0.90), itemType: 'charge', sortOrder: 0),
          LineItemModel(id: '${b.id}-t1', billId: b.id,
              description: 'Taxes and surcharges',
              amount: _r(total * 0.07), itemType: 'tax', sortOrder: 1),
          LineItemModel(id: '${b.id}-f1', billId: b.id,
              description: 'Service fee',
              amount: _r(total * 0.03), itemType: 'fee', sortOrder: 2),
        ]);
      }
      map[b.id] = items;
    }
    return map;
  }

  static double _r(double v) => (v * 100).round() / 100;

  static String _serviceChargeLabel(String serviceType) {
    switch (serviceType) {
      case 'water':     return 'Water and sewer';
      case 'internet':  return 'Internet service';
      case 'phone':     return 'Wireless plan';
      case 'streaming': return 'Subscription';
      default:          return 'Service charge';
    }
  }

  static final Map<String, List<LineItemModel>> _lineItemsByBill =
      _generateLineItems();

  static const _extractionFieldsFeb25 = [
    ExtractionFieldModel(
      id: 'ef1', billId: _detailBillId,
      fieldName: 'amount_due', rawValue: '\$176.40', parsedValue: 176.40,
      confidence: 0.98,
      boundingBox: BoundingBox(x: 412, y: 148, w: 120, h: 28),
    ),
    ExtractionFieldModel(
      id: 'ef2', billId: _detailBillId,
      fieldName: 'due_date', rawValue: 'March 18, 2025', parsedValue: null,
      confidence: 0.99,
      boundingBox: BoundingBox(x: 412, y: 186, w: 160, h: 22),
    ),
    ExtractionFieldModel(
      id: 'ef3', billId: _detailBillId,
      fieldName: 'kwh_used', rawValue: '910 kWh', parsedValue: 910.0,
      confidence: 0.96,
      boundingBox: BoundingBox(x: 180, y: 310, w: 90, h: 22),
    ),
    ExtractionFieldModel(
      id: 'ef4', billId: _detailBillId,
      fieldName: 'rate_per_kwh', rawValue: '0.0981 \$/kWh', parsedValue: 0.0981,
      confidence: 0.91,
      boundingBox: BoundingBox(x: 290, y: 310, w: 130, h: 22),
    ),
  ];

  // ── Interface implementation ───────────────────────────────────────────

  @override
  Future<List<Property>> getProperties() async => [_property];

  @override
  Future<Property> createProperty({required String name, String? address}) async {
    throw UnimplementedError('FakeBillRepository: createProperty not needed in dev');
  }

  @override
  Future<List<Account>> getAccounts({String? propertyId}) async => _accounts;

  @override
  Future<Account> createAccount({
    required String propertyId,
    required String provider,
    required String serviceType,
    String? accountNumber,
  }) async {
    throw UnimplementedError('FakeBillRepository: createAccount');
  }

  @override
  Future<List<Bill>> getBillsDue() async {
    // Return most recent bill per provider, ordered by due date.
    // User-added bills take priority over seed bills for the same provider.
    final all = [..._userBills, ..._bills]
        .where((b) => !_deletedIds.contains(b.id))
        .map(_applyEdits);
    final byProvider = <String, Bill>{};
    for (final bill in all) {
      if (!byProvider.containsKey(bill.provider)) {
        byProvider[bill.provider] = bill;
      }
    }
    final result = byProvider.values.toList()
      ..sort((a, b) => (a.dueDate ?? DateTime(2099))
          .compareTo(b.dueDate ?? DateTime(2099)));
    return result;
  }

  /// Overlays any in-memory edits (M15) on top of a seed/user bill.
  static Bill _applyEdits(Bill b) {
    final e = _edits[b.id];
    if (e == null) return b;
    DateTime? parseDate(dynamic v) => v is DateTime
        ? v
        : (v is String && v.isNotEmpty ? DateTime.tryParse(v) : null);
    return Bill(
      id: b.id,
      accountId: b.accountId,
      provider: (e['provider'] as String?) ?? b.provider,
      serviceType: (e['service_type'] as String?) ?? b.serviceType,
      amountDue: e.containsKey('amount_due')
          ? (e['amount_due'] as num?)?.toDouble()
          : b.amountDue,
      dueDate: e.containsKey('due_date') ? parseDate(e['due_date']) : b.dueDate,
      periodStart: b.periodStart,
      periodEnd: b.periodEnd,
      extractionStatus: b.extractionStatus,
      narrationSentence:
          (e['narration_sentence'] as String?) ?? b.narrationSentence,
      isPaid: b.isPaid,
    );
  }

  @override
  Future<BillDetail> getBillById(String id) async {
    // Check user-added bills first.
    Bill? userBill;
    for (final b in _userBills) {
      if (b.id == id) { userBill = b; break; }
    }
    if (userBill != null) {
      final ub = _applyEdits(userBill);
      return BillDetail(
        id: ub.id,
        accountId: ub.accountId,
        provider: ub.provider,
        serviceType: ub.serviceType,
        amountDue: ub.amountDue,
        dueDate: ub.dueDate,
        periodStart: ub.periodStart,
        periodEnd: ub.periodEnd,
        extractionStatus: ub.extractionStatus,
        narrationSentence:
            _narrationOverrides[ub.id] ?? ub.narrationSentence,
        rawImagePath: null,
        extractionFields: const [],
        lineItems: const [],
        anomalies: const [],
      );
    }

    final seed = _bills.firstWhere(
      (b) => b.id == id,
      orElse: () => _bills.first,
    );
    final bill = _applyEdits(seed);
    return BillDetail(
      id: bill.id,
      accountId: bill.accountId,
      provider: bill.provider,
      serviceType: bill.serviceType,
      amountDue: bill.amountDue,
      dueDate: bill.dueDate,
      periodStart: bill.periodStart,
      periodEnd: bill.periodEnd,
      extractionStatus: bill.extractionStatus,
      narrationSentence:
          _narrationOverrides[bill.id] ?? bill.narrationSentence,
      rawImagePath: null,
      extractionFields: bill.id == _detailBillId
          ? _extractionFieldsFeb25 : [],
      lineItems: bill.id == _detailBillId
          ? _lineItemsFeb25Electric
          : (_lineItemsByBill[bill.id] ?? []),
      anomalies: [],
    );
  }

  @override
  Future<List<Bill>> getAllBills({String? propertyId}) async {
    // Chronological (oldest first) to match the Supabase impl.
    final list = [..._bills, ..._userBills]
        .where((b) => !_deletedIds.contains(b.id))
        .map(_applyEdits)
        .toList()
      ..sort((a, b) => (a.periodEnd ?? DateTime(2000))
          .compareTo(b.periodEnd ?? DateTime(2000)));
    return list;
  }

  @override
  Future<Map<String, List<LineItemModel>>> getLineItemsForBills(
      List<String> billIds) async {
    final result = <String, List<LineItemModel>>{};
    for (final id in billIds) {
      final items = _lineItemsByBill[id];
      if (items != null) result[id] = items;
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> createBill(Map<String, dynamic> data) async {
    final id = (data['id'] as String?) ??
        'fake-new-bill-${DateTime.now().millisecondsSinceEpoch}';

    DateTime? parseDate(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

    // Record the created bill so getBillById / getBillsDue can return it.
    _userBills.insert(0, Bill(
      id: id,
      accountId: (data['account_id'] as String?) ?? 'manual',
      provider: (data['provider'] as String?) ??
          (data['name'] as String?) ?? 'Bill',
      serviceType: (data['service_type'] as String?) ?? 'other',
      amountDue: (data['amount_due'] as num?)?.toDouble(),
      dueDate: parseDate(data['due_date']),
      periodStart: parseDate(data['period_start']),
      periodEnd: parseDate(data['period_end']) ?? DateTime.now(),
      extractionStatus: (data['extraction_status'] as String?) ?? 'done',
      narrationSentence: data['narration_sentence'] as String?,
    ));
    _bump();
    return {'id': id, ...data};
  }

  @override
  Future<void> updateBillStatus(String billId, String status) async {}

  @override
  Future<void> updateBillNarration(String billId, String sentence) async {
    _narrationOverrides[billId] = sentence;
  }

  @override
  Future<void> upsertExtractionFields(List<Map<String, dynamic>> fields) async {}

  @override
  Future<void> updateBill(String billId, Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    // Merge into existing overrides so successive edits accumulate.
    final existing = _edits[billId] ?? <String, dynamic>{};
    _edits[billId] = {...existing, ...changes};
    _bump();
  }

  @override
  Future<void> deleteBill(String billId) async {
    _deletedIds.add(billId);
    _bump();
  }

  /// Restore a soft-deleted bill (used by the list/detail Undo affordance).
  static void restoreBill(String billId) {
    _deletedIds.remove(billId);
    _bump();
  }

  @override
  Future<String> uploadBillImage({
    required String userId,
    required String billId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return '$userId/$billId/$fileName'; // fake path
  }

  @override
  Future<String> getSignedImageUrl(String path) async {
    // Return a placeholder image URL for dev
    return 'https://placehold.co/800x1100/F2F2F7/000000.png?text=Bill+Image';
  }

  @override
  Future<void> dismissAnomaly(String anomalyId) async {}

  @override
  Future<void> markAnomalyWrong(String anomalyId) async {}
}

/// Internal seed descriptor for one tracked service (offline demo data).
class _SeedService {
  const _SeedService(
    this.account,
    this.provider,
    this.serviceType,
    this.series,
    this.idSeg,
    this.dueOffset,
    this.noun,
  );
  final String account;
  final String provider;
  final String serviceType;
  final List<double> series;
  final String idSeg;
  final int dueOffset;
  final String noun;
}
