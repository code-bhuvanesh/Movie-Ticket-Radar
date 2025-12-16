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

  bool getTelegramNotifEnabled() {
    return prefs.getBool(StorageKeys.enableTelegramNotif) ?? false;
  }

  Future<void> setTelegramNotifEnabled(bool value) async {
    await prefs.setBool(StorageKeys.enableTelegramNotif, value);
  }

  // ==================== Telegram Settings ====================

  String getTelegramBotToken() {
    return prefs.getString(StorageKeys.telegramBotToken) ?? '';
  }

  Future<void> setTelegramBotToken(String value) async {
    await prefs.setString(StorageKeys.telegramBotToken, value);
  }

  String getTelegramChatId() {
    return prefs.getString(StorageKeys.telegramChatId) ?? '';
  }

  Future<void> setTelegramChatId(String value) async {
    await prefs.setString(StorageKeys.telegramChatId, value);
  }

  // ==================== Time Range ====================

  String getTimeRange() {
    return prefs.getString(StorageKeys.timeRange) ??
        ApiConstants.defaultTimeRange;
  }

  Future<void> setTimeRange(String value) async {
    await prefs.setString(StorageKeys.timeRange, value);
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

  // ==================== Debug ====================

  /// Print all stored keys (for debugging)
  void debugPrintAll() {
    debugPrint('===== StorageService Debug =====');
    debugPrint('Tasks: ${getTasks().length} chars');
    debugPrint('Windows Notif: ${getWindowsNotifEnabled()}');
    debugPrint('Telegram Notif: ${getTelegramNotifEnabled()}');
    debugPrint('Theme Dark: ${getIsDarkTheme()}');
    debugPrint('Logs: ${getLogs().length} entries');
    debugPrint('================================');
  }
}
