import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Service for persisting app settings and tasks using SharedPreferences
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static SharedPreferences? _prefs;
  static bool _initialized = false;

  /// Initialize the storage service - call this at app startup
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      debugPrint('StorageService initialized');
    } catch (e) {
      debugPrint('Error initializing StorageService: $e');
      rethrow;
    }
  }

  /// Get the SharedPreferences instance
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError(
        'StorageService not initialized. Call StorageService.initialize() first.',
      );
    }
    return _prefs!;
  }

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Reload preferences from disk (important for background isolates)
  Future<void> reload() async {
    await prefs.reload();
  }

  // ==================== Tasks ====================

  String getTasks() {
    try {
      final value = prefs.getString(StorageKeys.tasks);
      debugPrint('Getting tasks: ${value?.length ?? 0} chars');
      return value ?? '[]';
    } catch (e) {
      debugPrint('Error getting tasks: $e');
      return '[]';
    }
  }

  Future<void> saveTasks(String tasksJson) async {
    try {
      await prefs.setString(StorageKeys.tasks, tasksJson);
      debugPrint('Saved tasks: ${tasksJson.length} chars');
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  // ==================== Notification Settings ====================

  bool getWindowsNotifEnabled() {
    return prefs.getBool(StorageKeys.enableWindowsNotif) ?? true;
  }

  Future<void> setWindowsNotifEnabled(bool value) async {
    await prefs.setBool(StorageKeys.enableWindowsNotif, value);
  }

  // ==================== Theme ====================

  bool getIsDarkTheme() {
    return prefs.getBool(StorageKeys.isDarkTheme) ?? true;
  }

  Future<void> setIsDarkTheme(bool value) async {
    await prefs.setBool(StorageKeys.isDarkTheme, value);
  }

  // ==================== Selected City ====================

  int? getSelectedCityId() {
    return prefs.getInt(StorageKeys.selectedCityId);
  }

  String? getSelectedCityName() {
    return prefs.getString(StorageKeys.selectedCityName);
  }

  Future<void> setSelectedCity(int? cityId, String? cityName) async {
    if (cityId != null) {
      await prefs.setInt(StorageKeys.selectedCityId, cityId);
    } else {
      await prefs.remove(StorageKeys.selectedCityId);
    }
    if (cityName != null) {
      await prefs.setString(StorageKeys.selectedCityName, cityName);
    } else {
      await prefs.remove(StorageKeys.selectedCityName);
    }
  }

  // ==================== Logs ====================

  List<String> getLogs() {
    return prefs.getStringList(StorageKeys.logs) ?? [];
  }

  Future<void> addLog(String log) async {
    final logs = getLogs();
    logs.add(log);
    // Keep only last 500 logs
    if (logs.length > 500) {
      logs.removeRange(0, logs.length - 500);
    }
    await prefs.setStringList(StorageKeys.logs, logs);
  }

  Future<void> clearLogs() async {
    await prefs.setStringList(StorageKeys.logs, []);
  }

  // ==================== Notified Sessions ====================

  /// Get set of notified session keys (taskId_showTime_date)
  Set<String> getNotifiedSessions() {
    final list = prefs.getStringList(StorageKeys.notifiedSessions) ?? [];
    return list.toSet();
  }

  /// Add a session key to notified sessions
  Future<void> addNotifiedSession(String sessionKey) async {
    final sessions = getNotifiedSessions();
    sessions.add(sessionKey);
    // Keep only last 1000 sessions to avoid memory issues
    final sessionsList = sessions.toList();
    if (sessionsList.length > 1000) {
      sessionsList.removeRange(0, sessionsList.length - 1000);
    }
    await prefs.setStringList(StorageKeys.notifiedSessions, sessionsList);
  }

  /// Add multiple session keys to notified sessions
  Future<void> addNotifiedSessions(List<String> sessionKeys) async {
    final sessions = getNotifiedSessions();
    sessions.addAll(sessionKeys);
    // Keep only last 1000 sessions to avoid memory issues
    final sessionsList = sessions.toList();
    if (sessionsList.length > 1000) {
      sessionsList.removeRange(0, sessionsList.length - 1000);
    }
    await prefs.setStringList(StorageKeys.notifiedSessions, sessionsList);
  }

  /// Clear all notified sessions (usually when task is deleted)
  Future<void> clearNotifiedSessions() async {
    await prefs.setStringList(StorageKeys.notifiedSessions, []);
  }

  /// Clear notified sessions for a specific task
  Future<void> clearNotifiedSessionsForTask(String taskId) async {
    final sessions = getNotifiedSessions();
    sessions.removeWhere((key) => key.startsWith('${taskId}_'));
    await prefs.setStringList(StorageKeys.notifiedSessions, sessions.toList());
  }

  // ==================== Background Run Time ====================

  /// Get the last time the background check ran
  DateTime? getLastBackgroundRun() {
    final value = prefs.getString(StorageKeys.lastBackgroundRun);
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }

  /// Set the last time the background check ran
  Future<void> setLastBackgroundRun(DateTime time) async {
    await prefs.setString(
      StorageKeys.lastBackgroundRun,
      time.toIso8601String(),
    );
  }

  // ==================== Debug Settings ====================

  /// Get debug force notify flag (bypasses notification cache)
  bool getDebugForceNotify() {
    return prefs.getBool(StorageKeys.debugForceNotify) ?? false;
  }

  /// Set debug force notify flag
  Future<void> setDebugForceNotify(bool value) async {
    await prefs.setBool(StorageKeys.debugForceNotify, value);
  }

  // ==================== Debug ====================

  /// Print all stored keys (for debugging)
  void debugPrintAll() {
    debugPrint('===== StorageService Debug =====');
    debugPrint('Tasks: ${getTasks().length} chars');
    debugPrint('Windows Notif: ${getWindowsNotifEnabled()}');
    debugPrint('Theme Dark: ${getIsDarkTheme()}');
    debugPrint('Logs: ${getLogs().length} entries');
    debugPrint('Last Background Run: ${getLastBackgroundRun()}');
    debugPrint('================================');
  }
}
