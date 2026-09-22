// lib/shared/data/bill_repository.dart
// ------------------------------------
// Repository layer — screens depend on this, never on SupabaseService directly.
// Makes it easy to swap to a fake implementation in tests.
//
// Real implementation (default) delegates to SupabaseService.
// Fake implementation (for tests) is in test/fakes/fake_bill_repository.dart.

import 'dart:typed_data';
import '../models/bill.dart';
import '../models/property.dart';
import '../models/account.dart';
import '../models/line_item.dart';
import '../services/supabase_client.dart';

// ── Abstract interface ─────────────────────────────────────────────────────

abstract class BillRepository {
  // Properties
  Future<List<Property>> getProperties();
  Future<Property> createProperty({required String name, String? address});

  // Accounts
  Future<List<Account>> getAccounts({String? propertyId});
  Future<Account> createAccount({
    required String propertyId,
    required String provider,
    required String serviceType,
    String? accountNumber,
  });

  // Bills — home screen
  Future<List<Bill>> getBillsDue();

  // Bills — dashboard (full history, all providers, chronological)
  Future<List<Bill>> getAllBills({String? propertyId});

  // Line items for a set of bills — dashboard category breakdown.
  // Returns a map of bill id → its line items.
  Future<Map<String, List<LineItemModel>>> getLineItemsForBills(
      List<String> billIds);

  // Bills — detail screen
  Future<BillDetail> getBillById(String id);

  // Bills — write
  Future<Map<String, dynamic>> createBill(Map<String, dynamic> data);
  Future<void> updateBillStatus(String billId, String status);
  Future<void> updateBillNarration(String billId, String sentence);
  Future<void> upsertExtractionFields(List<Map<String, dynamic>> fields);

  // Bills — edit / delete (M15). Edit applies a partial field change;
  // delete removes the bill (soft-delete semantics in the fake repo so the
  // list can offer an Undo).
  Future<void> updateBill(String billId, Map<String, dynamic> changes);
  Future<void> deleteBill(String billId);

  // Storage
  Future<String> uploadBillImage({
    required String userId,
    required String billId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
  Future<String> getSignedImageUrl(String path);

  // Anomalies
  Future<void> dismissAnomaly(String anomalyId);
  Future<void> markAnomalyWrong(String anomalyId);
}

// ── Supabase-backed implementation ─────────────────────────────────────────

class SupabaseBillRepository implements BillRepository {
  SupabaseBillRepository([SupabaseService? service])
      : _svc = service ?? SupabaseService.instance;

  final SupabaseService _svc;

  // ── Properties ────────────────────────────────────────────────────────
  @override
  Future<List<Property>> getProperties() async {
    final rows = await _svc.getProperties();
    return rows.map(Property.fromJson).toList();
  }

  @override
  Future<Property> createProperty({
    required String name,
    String? address,
  }) async {
    final row = await _svc.createProperty(name: name, address: address);
    return Property.fromJson(row);
  }

  // ── Accounts ──────────────────────────────────────────────────────────
  @override
  Future<List<Account>> getAccounts({String? propertyId}) async {
    // SupabaseService.getAccounts does not exist yet — add it here via SDK
    final client = _svc.client;
    var query = client.from('accounts').select();
    if (propertyId != null) {
      query = query.eq('property_id', propertyId);
    }
    final rows = await query.order('provider') as List;
    return rows
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Account> createAccount({
    required String propertyId,
    required String provider,
    required String serviceType,
    String? accountNumber,
  }) async {
    final client = _svc.client;
    final row = await client.from('accounts').insert({
      'property_id':     propertyId,
      'provider':        provider,
      'service_type':    serviceType,
      if (accountNumber != null) 'account_number': accountNumber,
      'user_id':         _svc.currentUser!.id,
    }).select().single();
    return Account.fromJson(row);
  }

  // ── Bills — home ──────────────────────────────────────────────────────
  @override
  Future<List<Bill>> getBillsDue() async {
    final rows = await _svc.getBillsDue();
    return rows.map(Bill.fromJson).toList();
  }

  // ── Bills — dashboard ─────────────────────────────────────────────────
  @override
  Future<List<Bill>> getAllBills({String? propertyId}) async {
    final client = _svc.client;
    var query = client.from('bills').select(
      'id, account_id, amount_due, due_date, period_start, period_end, '
      'extraction_status, narration_sentence, '
      'accounts!inner(provider, service_type, property_id)',
    );
    if (propertyId != null) {
      query = query.eq('accounts.property_id', propertyId);
    }
    final rows = await query.order('period_end', ascending: true) as List;
    return rows
        .map((e) => Bill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, List<LineItemModel>>> getLineItemsForBills(
      List<String> billIds) async {
    if (billIds.isEmpty) return {};
    final client = _svc.client;
    final rows = await client
        .from('line_items')
        .select()
        .inFilter('bill_id', billIds)
        .order('sort_order') as List;
    final result = <String, List<LineItemModel>>{};
    for (final r in rows) {
      final li = LineItemModel.fromJson(r as Map<String, dynamic>);
      (result[li.billId] ??= <LineItemModel>[]).add(li);
    }
    return result;
  }

  // ── Bills — detail ────────────────────────────────────────────────────
  @override
  Future<BillDetail> getBillById(String id) async {
    final row = await _svc.getBillById(id);
    return BillDetail.fromJson(row);
  }

  // ── Bills — write ─────────────────────────────────────────────────────
  @override
  Future<Map<String, dynamic>> createBill(Map<String, dynamic> data) =>
      _svc.createBill(data);

  @override
  Future<void> updateBillStatus(String billId, String status) =>
      _svc.updateBillExtractionStatus(billId, status);

  @override
  Future<void> updateBillNarration(String billId, String sentence) async {
    final client = _svc.client;
    await client
        .from('bills')
        .update({'narration_sentence': sentence})
        .eq('id', billId);
  }

  @override
  Future<void> upsertExtractionFields(List<Map<String, dynamic>> fields) =>
      _svc.upsertExtractionFields(fields);

  @override
  Future<void> updateBill(String billId, Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    final client = _svc.client;
    await client.from('bills').update(changes).eq('id', billId);
  }

  @override
  Future<void> deleteBill(String billId) async {
    final client = _svc.client;
    await client.from('bills').delete().eq('id', billId);
  }

  // ── Storage ───────────────────────────────────────────────────────────
  @override
  Future<String> uploadBillImage({
    required String userId,
    required String billId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) =>
      _svc.uploadBillImage(
        userId:   userId,
        billId:   billId,
        fileName: fileName,
        bytes:    bytes.toList(),
        mimeType: mimeType,
      );

  @override
  Future<String> getSignedImageUrl(String path) =>
      _svc.getSignedImageUrl(path);

  // ── Anomalies ─────────────────────────────────────────────────────────
  @override
  Future<void> dismissAnomaly(String anomalyId) =>
      _svc.dismissAnomaly(anomalyId);

  @override
  Future<void> markAnomalyWrong(String anomalyId) =>
      _svc.markAnomalyWrong(anomalyId);
}
