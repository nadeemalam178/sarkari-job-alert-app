import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import 'dart:math';

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
  static const String _keyCandidateQualification = 'candidate_qualification';
  static const String _keyNotificationsEnabled = 'candidate_notif_enabled';
  static const String _keyIsLoggedIn = 'app_user_is_logged_in';
  static const String _keyNotificationBannerDismissed =
      'notif_banner_dismissed';
  static const String _keyRegisteredAccounts = 'registered_accounts_json';

  // --- Password Hashing (SHA-256 with salt) ---
  static String _hashPassword(String password, [String? salt]) {
    salt ??= _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:$digest';
  }

  static String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  static bool _verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      final salt = parts[0];
      final computed = _hashPassword(password, salt);
      return computed == storedHash;
    } catch (_) {
      return false;
    }
  }

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
    await prefs.remove(_keyCandidateCategory);
    await prefs.remove(_keyCandidateState);
    await prefs.remove(_keyCandidateQualification);
    await prefs.remove(_keySavedJobIds);
    await prefs.remove(_keyRegisteredAccounts);
    await prefs.remove(_keyCachedJobs);
    await prefs.setBool(_keyNotificationBannerDismissed, false);
    await prefs.setStringList(_keySelectedQuals, ['GRADUATE', '12TH / 10+2']);
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

  // --- Theme Mode ---
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
      'name': prefs.getString(_keyCandidateName) ?? 'Candidate',
      'email': prefs.getString(_keyCandidateEmail) ?? '',
      'phone': prefs.getString(_keyCandidatePhone) ?? '',
      'category': prefs.getString(_keyCandidateCategory) ?? 'General / OBC',
      'state': prefs.getString(_keyCandidateState) ?? 'All India',
      'qualification':
          prefs.getString(_keyCandidateQualification) ?? 'GRADUATE',
      'notifEnabled': (prefs.getBool(_keyNotificationsEnabled) ?? true)
          .toString(),
    };
  }

  static Future<void> updateCandidateProfile({
    required String name,
    required String email,
    required String phone,
    String category = 'General / OBC',
    String state = 'All India',
    String qualification = 'GRADUATE',
    bool notifEnabled = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCandidateName, name.trim());
    await prefs.setString(_keyCandidateEmail, email.trim().toLowerCase());
    await prefs.setString(_keyCandidatePhone, phone.trim());
    await prefs.setString(_keyCandidateCategory, category.trim());
    await prefs.setString(_keyCandidateState, state.trim());
    await prefs.setString(_keyCandidateQualification, qualification.trim());
    await prefs.setBool(_keyNotificationsEnabled, notifEnabled);
  }

  // --- Production Account Registration & Verification ---
  static Future<Map<String, dynamic>> registerNewAccount({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String qualification,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawAccounts = prefs.getString(_keyRegisteredAccounts);
    final Map<String, dynamic> accounts = rawAccounts != null
        ? jsonDecode(rawAccounts)
        : {};

    final normalizedEmail = email.trim().toLowerCase();
    if (accounts.containsKey(normalizedEmail)) {
      return {
        'success': false,
        'error': 'An account with this email already exists. Please sign in.',
      };
    }

    accounts[normalizedEmail] = {
      'name': name.trim(),
      'email': normalizedEmail,
      'password': _hashPassword(password),
      'phone': phone.trim(),
      'qualification': qualification.trim(),
      'registered_at': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_keyRegisteredAccounts, jsonEncode(accounts));

    // Save active profile
    await updateCandidateProfile(
      name: name,
      email: normalizedEmail,
      phone: phone,
      qualification: qualification,
    );

    // Save initial qualifications matching hierarchy
    await setSelectedQualifications([
      qualification,
      if (qualification == 'B.SC') 'GRADUATE',
      '12TH / 10+2',
    ]);

    await setLoggedIn(true);
    return {'success': true};
  }

  static Future<Map<String, dynamic>> loginAccount({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawAccounts = prefs.getString(_keyRegisteredAccounts);
    final Map<String, dynamic> accounts = rawAccounts != null
        ? jsonDecode(rawAccounts)
        : {};

    final normalizedEmail = email.trim().toLowerCase();
    if (!accounts.containsKey(normalizedEmail)) {
      return {
        'success': false,
        'error': 'Account does not exist. Please create an account first.',
      };
    }

    final account = accounts[normalizedEmail] as Map<String, dynamic>;
    if (!_verifyPassword(password, account['password'] as String)) {
      return {
        'success': false,
        'error': 'Incorrect password. Please verify and try again.',
      };
    }

    // Set active candidate
    await updateCandidateProfile(
      name: account['name'] ?? 'Candidate',
      email: normalizedEmail,
      phone: account['phone'] ?? '',
      qualification: account['qualification'] ?? 'GRADUATE',
    );

    final qual = account['qualification'] ?? 'GRADUATE';
    await setSelectedQualifications([
      qual,
      if (qual == 'B.SC') 'GRADUATE',
      '12TH / 10+2',
    ]);

    await setLoggedIn(true);
    return {'success': true};
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyCandidateName);
    await prefs.remove(_keyCandidateEmail);
    await prefs.remove(_keyCandidatePhone);
    await prefs.remove(_keyCandidateCategory);
    await prefs.remove(_keyCandidateState);
    await prefs.remove(_keyCandidateQualification);
    await prefs.remove(_keySavedJobIds);
    await prefs.remove(_keyCachedJobs);
    await prefs.setStringList(_keySelectedQuals, ['GRADUATE', '12TH / 10+2']);
  }

  static Future<List<String>> getSelectedQualifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySelectedQuals) ??
        ['GRADUATE', '12TH / 10+2'];
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
    final current = await getSavedJobIds();
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    await prefs.setStringList(
      _keySavedJobIds,
      current.map((e) => e.toString()).toList(),
    );
  }

  static Future<List<JobPost>> getCachedJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCachedJobs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((e) => JobPost.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> cacheJobs(List<JobPost> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(jobs.map((e) => e.toJson()).toList());
    await prefs.setString(_keyCachedJobs, raw);
  }
}
