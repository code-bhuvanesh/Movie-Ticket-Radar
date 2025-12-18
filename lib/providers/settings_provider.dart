import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Settings state
class SettingsState {
  final bool enableWindowsNotif;

  final bool isDarkTheme;

  const SettingsState({
    this.enableWindowsNotif = true,
    this.isDarkTheme = true,
  });

  SettingsState copyWith({bool? enableWindowsNotif, bool? isDarkTheme}) {
    return SettingsState(
      enableWindowsNotif: enableWindowsNotif ?? this.enableWindowsNotif,
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

  void _loadSettings() {
    try {
      final settings = SettingsState(
        enableWindowsNotif: _storageService.getWindowsNotifEnabled(),
        isDarkTheme: _storageService.getIsDarkTheme(),
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
    loadLogs();
  }

  void loadLogs() {
    try {
      state = _storageService.getLogs();
      debugPrint('Loaded ${state.length} logs');
    } catch (e) {
      debugPrint('Error loading logs: $e');
    }
  }

  /// Refresh logs from storage (call after background service adds logs)
  void refresh() {
    loadLogs();
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
