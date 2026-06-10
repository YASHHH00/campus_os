import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Wrapper around [SharedPreferences] for type-safe access to app settings.
///
/// Provides getter/setter pairs for each preference key defined in
/// [AppConstants]. All methods are async since SharedPreferences operations
/// are asynchronous on first access.
class PrefsService {
  static PrefsService? _instance;
  SharedPreferences? _prefs;

  PrefsService._();

  factory PrefsService() {
    _instance ??= PrefsService._();
    return _instance!;
  }

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> init() async {
    await _preferences;
  }

  // ── Notification Permission ───────────────────────────────────────────────

  Future<bool> get hasAskedNotificationPermission async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.prefNotifPermissionAsked) ?? false;
  }

  Future<void> setNotificationPermissionAsked(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.prefNotifPermissionAsked, value);
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  Future<bool> get isDarkMode async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.prefDarkMode) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.prefDarkMode, value);
  }

  // ── User Identity ─────────────────────────────────────────────────────────

  Future<String?> get userId async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.prefUserId);
  }

  Future<void> setUserId(String value) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.prefUserId, value);
  }

  Future<String?> get collegeId async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.prefCollegeId);
  }

  Future<void> setCollegeId(String value) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.prefCollegeId, value);
  }

  // ── Sync ──────────────────────────────────────────────────────────────────

  Future<String?> get lastSyncTimestamp async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.prefLastSyncTimestamp);
  }

  Future<void> setLastSyncTimestamp(String value) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.prefLastSyncTimestamp, value);
  }

  Future<String?> get pairedDeviceId async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.prefWebrtcPairedDeviceId);
  }

  Future<void> setPairedDeviceId(String? value) async {
    final prefs = await _preferences;
    if (value == null) {
      await prefs.remove(AppConstants.prefWebrtcPairedDeviceId);
    } else {
      await prefs.setString(AppConstants.prefWebrtcPairedDeviceId, value);
    }
  }

  // ── Clear All ─────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.clear();
  }
}
