// auth_state.dart
// ----------------
// ChangeNotifier wrapping Supabase Auth.
// Supports email/password sign-up and sign-in (+ demo login),
// plus OAuth (Google/Apple) kept for non-bypass mode.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shared/services/supabase_client.dart';

class AuthState extends ChangeNotifier {
  AuthState._();
  static final instance = AuthState._();

  Session? _session;
  Session? get session => _session;

  /// True when the user completed demo/bypass login without a real Supabase session.
  bool _bypassSignedIn = false;

  bool get isSignedIn => _session != null || _bypassSignedIn;
  String? get userId => _session?.user.id ?? (_bypassSignedIn ? '00000000-0000-0000-0000-000000000101' : null);

  /// Activate offline bypass mode directly (used at startup when
  /// BYPASS_AUTH=true and no real Supabase session is available, so the app
  /// lands on the app shell without showing the sign-in screen).
  void activateBypass() {
    if (_bypassSignedIn) return;
    _bypassSignedIn = true;
    notifyListeners();
  }

  void initialize() {
    try {
      final client = SupabaseService.instance.client;
      _session = client.auth.currentSession;
      client.auth.onAuthStateChange.listen((data) {
        _session = data.session;
        notifyListeners();
      });
    } catch (_) {
      // Supabase not initialised (offline mode) — skip
    }
  }

  // ── Email / Password ───────────────────────────────────────────────────

  Future<void> signUpWithEmail({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final client = SupabaseService.instance.client;
    final res = await client.auth.signUp(
      email:    email,
      password: password,
      data: {
        'name':     name,
        'username': username.toLowerCase(),
      },
    );
    if (res.user == null) {
      throw Exception('Sign-up failed. Please try again.');
    }
    // Upsert the profile row in case the trigger missed it (e.g. local dev)
    await client.from('profiles').upsert({
      'id':       res.user!.id,
      'username': username.toLowerCase(),
      'name':     name,
      'email':    email,
    });
    _session = res.session;
    notifyListeners();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = SupabaseService.instance.client;
    final res = await client.auth.signInWithPassword(
      email:    email,
      password: password,
    );
    _session = res.session;
    notifyListeners();
  }

  /// Demo login — tries Supabase first, falls back to offline bypass.
  Future<void> signInDemo({
    String email    = 'alice@split.local',
    String password = 'demo1234',
  }) async {
    try {
      await signInWithEmail(email: email, password: password);
    } catch (_) {
      // Supabase unavailable — activate offline bypass mode
      _bypassSignedIn = true;
      notifyListeners();
    }
  }

  // ── OAuth ──────────────────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    await SupabaseService.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.billapp://callback',
    );
  }

  Future<void> signInWithApple() async {
    await SupabaseService.instance.client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.billapp://callback',
    );
  }

  // ── Sign out ───────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await SupabaseService.instance.client.auth.signOut();
    } catch (_) {}
    _session = null;
    _bypassSignedIn = false;
    notifyListeners();
  }
}
