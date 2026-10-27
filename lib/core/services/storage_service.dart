import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/session_model.dart';

class StorageService {
  static const String keyOnboardingComplete = 'mawadda_onboarding_complete';
  static const String keyFavorites = 'mawadda_favorites';
  static const String keyAnsweredQuestions = 'mawadda_answered_questions';
  static const String keyThemeMode = 'mawadda_theme_mode'; // 'system', 'light', 'dark'
  static const String keyActiveSession = 'mawadda_active_session';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Onboarding
  bool isOnboardingComplete() {
    return _prefs.getBool(keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(keyOnboardingComplete, value);
  }

  // Favorites
  Set<String> getFavorites() {
    final list = _prefs.getStringList(keyFavorites) ?? [];
    return list.toSet();
  }

  Future<void> toggleFavorite(String questionId) async {
    final current = getFavorites();
    if (current.contains(questionId)) {
      current.remove(questionId);
    } else {
      current.add(questionId);
    }
    await _prefs.setStringList(keyFavorites, current.toList());
  }

  // Answered / Viewed Questions
  Set<String> getAnsweredQuestions() {
    final list = _prefs.getStringList(keyAnsweredQuestions) ?? [];
    return list.toSet();
  }

  Future<void> markQuestionViewed(String questionId) async {
    final current = getAnsweredQuestions();
    if (!current.contains(questionId)) {
      current.add(questionId);
      await _prefs.setStringList(keyAnsweredQuestions, current.toList());
    }
  }

  // Active Session
  SessionModel? getActiveSession() {
    final raw = _prefs.getString(keyActiveSession);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SessionModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveSession(SessionModel? session) async {
    if (session == null) {
      await _prefs.remove(keyActiveSession);
    } else {
      await _prefs.setString(keyActiveSession, jsonEncode(session.toJson()));
    }
  }

  // Theme
  String getThemeMode() {
    return _prefs.getString(keyThemeMode) ?? 'system';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(keyThemeMode, mode);
  }

  // Hide Answered Questions
  bool getHideAnswered() {
    return _prefs.getBool('mawadda_hide_answered') ?? false;
  }

  Future<void> setHideAnswered(bool value) async {
    await _prefs.setBool('mawadda_hide_answered', value);
  }

  // Notes on cards
  static const String keyNotes = 'mawadda_card_notes';

  String? getNote(String questionId) {
    final raw = _prefs.getString(keyNotes);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map[questionId] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveNote(String questionId, String note) async {
    final raw = _prefs.getString(keyNotes);
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        map = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    if (note.trim().isEmpty) {
      map.remove(questionId);
    } else {
      map[questionId] = note.trim();
    }
    await _prefs.setString(keyNotes, jsonEncode(map));
  }

  // Reset all progress
  Future<void> resetProgress() async {
    await _prefs.remove(keyAnsweredQuestions);
    await _prefs.remove(keyActiveSession);
    await _prefs.remove(keyNotes);
  }

  // Reset onboarding
  Future<void> resetOnboarding() async {
    await _prefs.remove(keyOnboardingComplete);
  }
}
