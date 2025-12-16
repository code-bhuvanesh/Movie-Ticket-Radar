import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monitoring_task.dart';
import '../models/show_session.dart';
import '../services/pvr_api_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

/// State for monitoring tasks
class TasksState {
  final List<MonitoringTask> tasks;
  final Set<String> runningTaskIds;
  final bool isLoading;

  const TasksState({
    this.tasks = const [],
    this.runningTaskIds = const {},
    this.isLoading = false,
  });

  TasksState copyWith({
    List<MonitoringTask>? tasks,
    Set<String>? runningTaskIds,
    bool? isLoading,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      runningTaskIds: runningTaskIds ?? this.runningTaskIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool isTaskRunning(String taskId) => runningTaskIds.contains(taskId);

  /// Get configured tasks only
  List<MonitoringTask> get configuredTasks =>
      tasks.where((t) => t.isConfigured).toList();
}

/// Notifier for monitoring tasks
class TasksNotifier extends StateNotifier<TasksState> {
  final StorageService _storageService;
  final PvrApiService _apiService;
  final NotificationService _notificationService;
  final Ref _ref;

  final Map<String, Timer> _taskTimers = {};

  TasksNotifier(
    this._storageService,
    this._apiService,
    this._notificationService,
    this._ref,
  ) : super(const TasksState()) {
    _loadTasks();
  }

  void _loadTasks() {
    state = state.copyWith(isLoading: true);
    try {
      final tasksJson = _storageService.getTasks();
      debugPrint('Loading tasks from storage: ${tasksJson.length} chars');
      final tasks = MonitoringTask.decodeList(tasksJson);
      state = state.copyWith(tasks: tasks, isLoading: false);
      debugPrint('Loaded ${tasks.length} tasks');
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveTasks() async {
    final json = MonitoringTask.encodeList(state.tasks);
    debugPrint('Saving ${state.tasks.length} tasks (${json.length} chars)');
    await _storageService.saveTasks(json);
  }

  /// Add a new task
  Future<void> addTask(MonitoringTask task) async {
    final tasks = [...state.tasks, task];
    state = state.copyWith(tasks: tasks);
    await _saveTasks();
    _ref.read(logsProvider.notifier).addLog('➕ Added: ${task.displayName}');
  }

  /// Update an existing task
  Future<void> updateTask(MonitoringTask task) async {
    final tasks = state.tasks.map((t) => t.id == task.id ? task : t).toList();
    state = state.copyWith(tasks: tasks);
    await _saveTasks();
    _ref.read(logsProvider.notifier).addLog('✏️ Updated: ${task.displayName}');
  }

  /// Remove a task
  Future<void> removeTask(String taskId) async {
    stopTask(taskId);
    final tasks = state.tasks.where((t) => t.id != taskId).toList();
    state = state.copyWith(tasks: tasks);
    await _saveTasks();
    _ref.read(logsProvider.notifier).addLog('🗑️ Removed task');
  }

  /// Start monitoring a task
  void startTask(String taskId) {
    final task = state.tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null || !task.isConfigured) {
      _ref
          .read(logsProvider.notifier)
          .addLog('⚠️ Cannot start unconfigured task');
      return;
    }

    final running = {...state.runningTaskIds, taskId};
    state = state.copyWith(runningTaskIds: running);

    _ref.read(logsProvider.notifier).addLog('▶️ Started: ${task.displayName}');

    // Start periodic checking
    _checkTask(taskId);
    _taskTimers[taskId] = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkTask(taskId),
    );
  }

  /// Stop monitoring a task
  void stopTask(String taskId) {
    _taskTimers[taskId]?.cancel();
    _taskTimers.remove(taskId);

    final running = {...state.runningTaskIds}..remove(taskId);
    state = state.copyWith(runningTaskIds: running);

    final task = state.tasks.where((t) => t.id == taskId).firstOrNull;
    if (task != null) {
      _ref
          .read(logsProvider.notifier)
          .addLog('⏹️ Stopped: ${task.displayName}');
    }
  }

  /// Toggle task running state
  void toggleTask(String taskId) {
    if (state.runningTaskIds.contains(taskId)) {
      stopTask(taskId);
    } else {
      startTask(taskId);
    }
  }

  /// Start all configured tasks
  void startAll() {
    for (final task in state.configuredTasks) {
      if (!state.runningTaskIds.contains(task.id)) {
        startTask(task.id);
      }
    }
  }

  /// Stop all tasks
  void stopAll() {
    for (final taskId in state.runningTaskIds.toList()) {
      stopTask(taskId);
    }
  }

  /// Check a task for available tickets
  Future<void> _checkTask(String taskId) async {
    final task = state.tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null ||
        !task.isConfigured ||
        !state.runningTaskIds.contains(taskId)) {
      return;
    }

    final settings = _ref.read(settingsProvider);
    final timeRange = _storageService.getTimeRange();
    final dateStrings = task.dateStrings;

    _ref
        .read(logsProvider.notifier)
        .addLog('🔍 Checking: ${task.movieName} (${dateStrings.length} days)');

    final List<ShowSession> foundSessions = [];

    // Check each date
    for (final dateStr in dateStrings) {
      if (!state.runningTaskIds.contains(taskId)) {
        break; // Stop if task was stopped
      }

      try {
        await Future.delayed(const Duration(seconds: 3)); // Rate limiting

        final sessions = await _apiService.fetchSessions(
          cityName: task.cityName!,
          movieId: task.movieId!,
          movieName: task.movieName!,
          date: dateStr,
          timeRange: timeRange,
          theatreId: task.theatreId,
        );

        // Filter by status
        for (final session in sessions) {
          bool matches = false;
          if (task.statuses.contains('available') && session.isAvailable) {
            matches = true;
          }
          if (task.statuses.contains('filling') && session.isFilling) {
            matches = true;
          }
          if (matches) {
            foundSessions.add(session);
          }
        }

        await Future.delayed(const Duration(seconds: 2)); // More rate limiting
      } catch (e) {
        _ref
            .read(logsProvider.notifier)
            .addLog('⚠️ Error checking $dateStr: $e');
      }
    }

    // Update last checked
    final updatedTasks = state.tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(lastChecked: DateTime.now());
      }
      return t;
    }).toList();
    state = state.copyWith(tasks: updatedTasks);
    await _saveTasks();

    // Send notifications
    if (foundSessions.isNotEmpty) {
      _ref
          .read(logsProvider.notifier)
          .addLog('🎫 Found ${foundSessions.length} shows!');

      // Platform notification
      if (settings.enableWindowsNotif) {
        final tickets = foundSessions
            .take(5)
            .map(
              (s) => {'title': s.notificationTitle, 'body': s.notificationBody},
            )
            .toList();
        await _notificationService.showTicketNotifications(tickets);
      }

      // Telegram notification
      if (settings.enableTelegramNotif &&
          settings.telegramBotToken.isNotEmpty) {
        for (final session in foundSessions.take(3)) {
          await _apiService.sendTelegramMessage(
            botToken: settings.telegramBotToken,
            chatId: settings.telegramChatId,
            message: session.htmlBody,
            parseHtml: true,
          );
          await Future.delayed(const Duration(seconds: 1));
        }
        _ref
            .read(logsProvider.notifier)
            .addLog('📤 Telegram notifications sent');
      }
    } else {
      _ref
          .read(logsProvider.notifier)
          .addLog('😴 ${task.displayName}: No tickets found');
    }
  }

  @override
  void dispose() {
    for (final timer in _taskTimers.values) {
      timer.cancel();
    }
    _taskTimers.clear();
    super.dispose();
  }
}

/// Provider for tasks
final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final storageService = StorageService();
  final apiService = PvrApiService();
  final notificationService = NotificationService();
  return TasksNotifier(storageService, apiService, notificationService, ref);
});
