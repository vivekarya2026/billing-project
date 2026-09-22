// current_user_state.dart
// ────────────────────────
// ChangeNotifier caching the current user's Profile.
// Populated after auth and invalidated on sign-out.

import 'package:flutter/material.dart';
import '../shared/models/profile.dart';
import '../shared/services/supabase_client.dart';

class CurrentUserState extends ChangeNotifier {
  CurrentUserState._();
  static final instance = CurrentUserState._();

  Profile? _profile;
  Profile? get profile => _profile;

  bool get isLoaded => _profile != null;

  Future<void> load(String userId) async {
    try {
      final row = await SupabaseService.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      _profile = Profile.fromJson(row);
      notifyListeners();
    } catch (_) {
      // Profile might not exist yet (e.g. trigger race); safe to ignore
    }
  }

  void setFakeProfile(Profile p) {
    _profile = p;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}
