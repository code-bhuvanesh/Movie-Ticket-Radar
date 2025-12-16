import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Service for persisting app settings and tasks
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Tasks
  Future<String> getTasks() async {
    final p = await prefs;
    return p.getString(StorageKeys.tasks) ?? '[]';
  }

  Future<void> saveTasks(String tasksJson) async {
    final p = await prefs;
    await p.setString(StorageKeys.tasks, tasksJson);
  }

  // Notification settings
  Future<bool> getWindowsNotifEnabled() async {
    final p = await prefs;
    return p.getBool(StorageKeys.enableWindowsNotif) ?? true;
  }

  Future<void> setWindowsNotifEnabled(bool value) async {
    final p = await prefs;
    await p.setBool(StorageKeys.enableWindowsNotif, value);
  }

  Future<bool> getTelegramNotifEnabled() async {
    final p = await prefs;
    return p.getBool(StorageKeys.enableTelegramNotif) ?? false;
  }

  Future<void> setTelegramNotifEnabled(bool value) async {
    final p = await prefs;
    await p.setBool(StorageKeys.enableTelegramNotif, value);
  }

  // Telegram settings
  Future<String> getTelegramBotToken() async {
    final p = await prefs;
    return p.getString(StorageKeys.telegramBotToken) ?? '';
  }

  Future<void> setTelegramBotToken(String value) async {
    final p = await prefs;
    await p.setString(StorageKeys.telegramBotToken, value);
  }

  Future<String> getTelegramChatId() async {
    final p = await prefs;
    return p.getString(StorageKeys.telegramChatId) ?? '';
  }

  Future<void> setTelegramChatId(String value) async {
    final p = await prefs;
    await p.setString(StorageKeys.telegramChatId, value);
  }

  // Time range
  Future<String> getTimeRange() async {
    final p = await prefs;
    return p.getString(StorageKeys.timeRange) ?? ApiConstants.defaultTimeRange;
  }

  Future<void> setTimeRange(String value) async {
    final p = await prefs;
    await p.setString(StorageKeys.timeRange, value);
  }

  // Theme
  Future<bool> getIsDarkTheme() async {
    final p = await prefs;
    return p.getBool(StorageKeys.isDarkTheme) ?? true;
  }

  Future<void> setIsDarkTheme(bool value) async {
    final p = await prefs;
    await p.setBool(StorageKeys.isDarkTheme, value);
  }

  // Logs
  Future<List<String>> getLogs() async {
    final p = await prefs;
    return p.getStringList(StorageKeys.logs) ?? [];
  }

  Future<void> addLog(String log) async {
    final p = await prefs;
    final logs = await getLogs();
    logs.add(log);
    // Keep only last 500 logs
    if (logs.length > 500) {
      logs.removeRange(0, logs.length - 500);
    }
    await p.setStringList(StorageKeys.logs, logs);
  }

  Future<void> clearLogs() async {
    final p = await prefs;
    await p.setStringList(StorageKeys.logs, []);
  }
}
