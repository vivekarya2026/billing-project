// supabase_client.dart
// ---------------------
// Typed Supabase helpers — tables, storage, auth.
// All queries are scoped to the authenticated user via RLS.
//
// BYPASS_AUTH mode: when env var BYPASS_AUTH=true, auth is skipped
// and a hardcoded test user ID is used. RLS still applies on the DB;
// the test user sees only their own data. Remove this flag before launch.

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class SupabaseService {
  SupabaseService._();
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Exposed for the repository layer (controlled access only).
  SupabaseClient get client => _client;

  // ── Auth ─────────────────────────────────────────────────────────────

  User? get currentUser => _client.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  // signInWithOAuth returns bool in supabase_flutter ≥ 2.x
  Future<void> signInWithGoogle() =>
      _client.auth.signInWithOAuth(OAuthProvider.google);

  Future<void> signInWithApple() =>
      _client.auth.signInWithOAuth(OAuthProvider.apple);

  Future<void> signOut() => _client.auth.signOut();

  Stream<dynamic> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // ── Properties ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProperties() async {
    final response = await _client
        .from('properties')
        .select()
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createProperty({
    required String name,
    String? address,
  }) async {
    final response = await _client.from('properties').insert({
      'name': name,
      if (address != null) 'address': address,
    }).select().single();
    return response;
  }

  // ── Bills ────────────────────────────────────────────────────────────

  /// Returns all bills ordered by due date — used for the unified due view (US-008).
  Future<List<Map<String, dynamic>>> getBillsDue() async {
    final response = await _client
        .from('bills')
        .select('''
          id, period_start, period_end, amount_due, due_date,
          bill_type, extraction_status, narration_sentence,
          accounts ( provider, service_type, property_id )
        ''')
        .order('due_date', ascending: true)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getBillById(String id) async {
    return await _client
        .from('bills')
        .select('''
          *,
          accounts ( provider, service_type ),
          extraction_fields ( * ),
          line_items ( * ),
          bill_classifications ( * ),
          anomalies ( * )
        ''')
        .eq('id', id)
        .single();
  }

  Future<Map<String, dynamic>> createBill(Map<String, dynamic> data) async {
    return await _client.from('bills').insert(data).select().single();
  }

  Future<void> updateBillExtractionStatus(
    String billId,
    String status,
  ) async {
    await _client
        .from('bills')
        .update({'extraction_status': status})
        .eq('id', billId);
  }

  // ── Extraction fields ────────────────────────────────────────────────

  Future<void> upsertExtractionFields(
    List<Map<String, dynamic>> fields,
  ) async {
    await _client.from('extraction_fields').upsert(fields);
  }

  // ── Storage (bill images) ────────────────────────────────────────────

  static const _bucket = 'bill-images';

  /// Upload a bill image. Returns the storage path.
  Future<String> uploadBillImage({
    required String userId,
    required String billId,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final path = '$userId/$billId/$fileName';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: mimeType),
        );
    return path;
  }

  /// Returns a signed URL valid for 1 hour. Used to pass image to AI service.
  Future<String> getSignedImageUrl(String path) async {
    return await _client.storage
        .from(_bucket)
        .createSignedUrl(path, 3600);
  }

  // ── Anomalies ────────────────────────────────────────────────────────

  Future<void> dismissAnomaly(String anomalyId) async {
    await _client
        .from('anomalies')
        .update({'user_dismissed': true})
        .eq('id', anomalyId);
  }

  Future<void> markAnomalyWrong(String anomalyId) async {
    await _client.from('anomalies').update({
      'user_confirmed_wrong': true,
    }).eq('id', anomalyId);
  }
}
