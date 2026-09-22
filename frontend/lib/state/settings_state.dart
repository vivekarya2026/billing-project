// lib/state/settings_state.dart
// ------------------------------
// Global settings state, persisted to shared_preferences.
// Provided at the app root via Provider.
//
// Keys:
//   detail_level   "brief" | "explained" | "full"
//   language       "en" | "es" (more later)
//   reminders      "off" | "day_before" | "day_of"

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Register enum ──────────────────────────────────────────────────────────

enum DetailLevel { brief, explained, full }

extension DetailLevelX on DetailLevel {
  String get label {
    switch (this) {
      case DetailLevel.brief:    return 'Brief';
      case DetailLevel.explained: return 'Explained';
      case DetailLevel.full:     return 'Full';
    }
  }

  static DetailLevel fromString(String s) {
    switch (s) {
      case 'explained': return DetailLevel.explained;
      case 'full':      return DetailLevel.full;
      default:          return DetailLevel.brief;
    }
  }
}

// ── Settings state ─────────────────────────────────────────────────────────

class SettingsState extends ChangeNotifier {
  SettingsState._();

  static final SettingsState _instance = SettingsState._();
  static SettingsState get instance => _instance;

  DetailLevel _detailLevel = DetailLevel.brief;
  String _language = 'en';
  String _reminders = 'off';
  bool _loaded = false;

  DetailLevel get detailLevel => _detailLevel;
  String get language => _language;
  String get reminders => _reminders;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _detailLevel = DetailLevelX.fromString(
        prefs.getString('detail_level') ?? 'brief');
    _language    = prefs.getString('language')  ?? 'en';
    _reminders   = prefs.getString('reminders') ?? 'off';
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDetailLevel(DetailLevel level) async {
    _detailLevel = level;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('detail_level', level.name);
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  Future<void> setReminders(String value) async {
    _reminders = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminders', value);
  }
}
