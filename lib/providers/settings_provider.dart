import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Settings state
class SettingsState {
  final bool enableWindowsNotif;
  final bool enableTelegramNotif;
  final String telegramBotToken;
  final String telegramChatId;
  final String timeRange;
  final bool isDarkTheme;

  const SettingsState({
    this.enableWindowsNotif = true,
    this.enableTelegramNotif = false,
    this.telegramBotToken = '',
    this.telegramChatId = '',
    this.timeRange = '08:00-24:00',
    this.isDarkTheme = true,
  });

  SettingsState copyWith({
    bool? enableWindowsNotif,
    bool? enableTelegramNotif,
    String? telegramBotToken,
    String? telegramChatId,
    String? timeRange,
    bool? isDarkTheme,
  }) {
    return SettingsState(
      enableWindowsNotif: enableWindowsNotif ?? this.enableWindowsNotif,
      enableTelegramNotif: enableTelegramNotif ?? this.enableTelegramNotif,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      timeRange: timeRange ?? this.timeRange,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storageService;

  SettingsNotifier(this._storageService) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = SettingsState(
        enableWindowsNotif: await _storageService.getWindowsNotifEnabled(),
        enableTelegramNotif: await _storageService.getTelegramNotifEnabled(),
        telegramBotToken: await _storageService.getTelegramBotToken(),
        telegramChatId: await _storageService.getTelegramChatId(),
        timeRange: await _storageService.getTimeRange(),
        isDarkTheme: await _storageService.getIsDarkTheme(),
      );
      state = settings;
      debugPrint('Settings loaded');
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> setWindowsNotifEnabled(bool value) async {
    state = state.copyWith(enableWindowsNotif: value);
    await _storageService.setWindowsNotifEnabled(value);
  }

  Future<void> setTelegramNotifEnabled(bool value) async {
    state = state.copyWith(enableTelegramNotif: value);
    await _storageService.setTelegramNotifEnabled(value);
  }

  Future<void> setTelegramBotToken(String value) async {
    state = state.copyWith(telegramBotToken: value);
    await _storageService.setTelegramBotToken(value);
  }

  Future<void> setTelegramChatId(String value) async {
    state = state.copyWith(telegramChatId: value);
    await _storageService.setTelegramChatId(value);
  }

  Future<void> setTimeRange(String value) async {
    state = state.copyWith(timeRange: value);
    await _storageService.setTimeRange(value);
  }

  Future<void> setDarkTheme(bool value) async {
    state = state.copyWith(isDarkTheme: value);
    await _storageService.setIsDarkTheme(value);
  }

  Future<void> toggleTheme() async {
    await setDarkTheme(!state.isDarkTheme);
  }
}

/// Provider for settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(StorageService());
  },
);

/// Logs state
class LogsNotifier extends StateNotifier<List<String>> {
  final StorageService _storageService;

  LogsNotifier(this._storageService) : super([]) {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    state = await _storageService.getLogs();
  }

  void addLog(String message) {
    final timestamp = DateTime.now();
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final logEntry = '[$timeStr] $message';
    state = [...state, logEntry];
    _storageService.addLog(logEntry);
  }

  Future<void> clear() async {
    state = [];
    await _storageService.clearLogs();
  }

  String get allLogsText => state.join('\n');
}

/// Provider for logs
final logsProvider = StateNotifierProvider<LogsNotifier, List<String>>((ref) {
  return LogsNotifier(StorageService());
});
