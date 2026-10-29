import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_post.dart';

class StorageService {
  static const String _keyServerUrl = 'server_base_url';
  static const String _keySelectedQuals = 'selected_qualifications';
  static const String _keySavedJobIds = 'saved_job_ids';
  static const String _keyCachedJobs = 'cached_jobs_json';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyCandidateName = 'candidate_name';
  static const String _keyCandidateEmail = 'candidate_email';
  static const String _keyCandidatePhone = 'candidate_phone';
  static const String _keyCandidateCategory = 'candidate_category';
  static const String _keyCandidateState = 'candidate_state';
  static const String _keyNotificationsEnabled = 'candidate_notif_enabled';
  static const String _keyIsLoggedIn = 'app_user_is_logged_in';
  static const String _keyNotificationBannerDismissed = 'notif_banner_dismissed';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> setLoggedIn(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, val);
  }

  static Future<bool> isBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationBannerDismissed) ?? false;
  }

  static Future<void> setBannerDismissed(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationBannerDismissed, val);
  }

  static Future<void> resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyCandidateName);
    await prefs.remove(_keyCandidateEmail);
    await prefs.remove(_keyCandidatePhone);
    await prefs.remove(_keySavedJobIds);
    await prefs.setBool(_keyNotificationBannerDismissed, false);
    // Set default degrees to include B.SC and GRADUATE
    await prefs.setStringList(_keySelectedQuals, ['B.SC', 'GRADUATE', '12TH / 10+2']);
  }

  static String getDefaultServerUrl() {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    return 'http://10.0.2.2:5000';
  }

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl) ?? getDefaultServerUrl();
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url.trim());
  }

  // --- Theme Mode (System auto-select default) ---
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  // --- Candidate Profile ---
  static Future<Map<String, String>> getCandidateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyCandidateName) ?? 'Nadeem Khan',
      'email': prefs.getString(_keyCandidateEmail) ?? 'nadeem.aspirant@sarkarialert.in',
      'phone': prefs.getString(_keyCandidatePhone) ?? '+91 98765 43210',
      'category': prefs.getString(_keyCandidateCategory) ?? 'General / OBC',
      'state': prefs.getString(_keyCandidateState) ?? 'All India / Central & States',
      'notifEnabled': (prefs.getBool(_keyNotificationsEnabled) ?? true).toString(),
    };
  }

  static Future<void> updateCandidateProfile({
    required String name,
    required String email,
    String phone = '+91 98765 43210',
    required String category,
    required String state,
    bool notifEnabled = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCandidateName, name.trim());
    await prefs.setString(_keyCandidateEmail, email.trim());
    await prefs.setString(_keyCandidatePhone, phone.trim());
    await prefs.setString(_keyCandidateCategory, category.trim());
    await prefs.setString(_keyCandidateState, state.trim());
    await prefs.setBool(_keyNotificationsEnabled, notifEnabled);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyCandidateName);
    await prefs.remove(_keyCandidateEmail);
    await prefs.remove(_keyCandidatePhone);
    await prefs.remove(_keyCandidateCategory);
    await prefs.remove(_keyCandidateState);
    await prefs.remove(_keySavedJobIds);
    await prefs.setStringList(_keySelectedQuals, ['B.SC', 'GRADUATE', '12TH / 10+2']);
  }

  static Future<List<String>> getSelectedQualifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySelectedQuals) ?? ['GRADUATE', '12TH / 10+2'];
  }

  static Future<void> setSelectedQualifications(List<String> quals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySelectedQuals, quals);
  }

  static Future<Set<int>> getSavedJobIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keySavedJobIds) ?? [];
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();
  }

  static Future<void> toggleSaveJobId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = (await getSavedJobIds()).toSet();
    if (saved.contains(id)) {
      saved.remove(id);
    } else {
      saved.add(id);
    }
    await prefs.setStringList(_keySavedJobIds, saved.map((e) => e.toString()).toList());
  }

  static Future<void> cacheJobs(List<JobPost> jobs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = jobs.map((j) => j.toJson()).toList();
      await prefs.setString(_keyCachedJobs, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Cache error: $e');
    }
  }

  static Future<List<JobPost>> getCachedJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyCachedJobs);
      if (str != null && str.isNotEmpty) {
        final List decoded = jsonDecode(str);
        return decoded.map((e) => JobPost.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Read cache error: $e');
    }
    return [];
  }
}
