import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../services/pvr_api_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../models/monitoring_task.dart';

/// Background task name for monitoring
const String kBackgroundTaskName = 'pvr_monitor_task';
const String kPeriodicTaskName = 'pvr_periodic_monitor';

/// Callback dispatcher for background tasks (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('Background task executing: $taskName');

    try {
      // Initialize services
      await StorageService.initialize();
      final storage = StorageService();
      final api = PvrApiService();
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Load tasks
      final tasksJson = storage.getTasks();
      final tasks = MonitoringTask.decodeList(tasksJson);
      final configuredTasks = tasks.where((t) => t.isConfigured).toList();

      debugPrint('Found ${configuredTasks.length} configured tasks');

      // Check each task
      for (final task in configuredTasks) {
        await _checkTaskInBackground(
          task: task,
          api: api,
          notificationService: notificationService,
          storage: storage,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Background task error: $e');
      return false;
    }
  });
}

/// Check a single task in background
Future<void> _checkTaskInBackground({
  required MonitoringTask task,
  required PvrApiService api,
  required NotificationService notificationService,
  required StorageService storage,
}) async {
  if (!task.isConfigured) return;

  final dateStrings = task.dateStrings;
  final timeRange = storage.getTimeRange();

  debugPrint('Checking: ${task.displayName} for ${dateStrings.length} dates');

  for (final dateStr in dateStrings) {
    try {
      await Future.delayed(const Duration(seconds: 2)); // Rate limiting

      final sessions = await api.fetchSessions(
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
          // Send notification
          await notificationService.showNotification(
            title: session.notificationTitle,
            body: session.notificationBody,
          );
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      debugPrint('Error checking $dateStr: $e');
    }
  }
}

/// Service for managing background tasks
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _isInitialized = false;

  /// Initialize background service (Android only)
  Future<void> initialize() async {
    if (!Platform.isAndroid || _isInitialized) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('Background service initialized');
    } catch (e) {
      debugPrint('Error initializing background service: $e');
    }
  }

  /// Register periodic background task
  Future<void> registerPeriodicTask({
    Duration frequency = const Duration(minutes: 15),
  }) async {
    if (!Platform.isAndroid) return;

    try {
      await Workmanager().registerPeriodicTask(
        kPeriodicTaskName,
        kBackgroundTaskName,
        frequency: frequency,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 1),
      );
      debugPrint('Periodic background task registered');
    } catch (e) {
      debugPrint('Error registering periodic task: $e');
    }
  }

  /// Run task once immediately
  Future<void> runOnce() async {
    if (!Platform.isAndroid) return;

    try {
      await Workmanager().registerOneOffTask(
        '${kBackgroundTaskName}_${DateTime.now().millisecondsSinceEpoch}',
        kBackgroundTaskName,
        constraints: Constraints(networkType: NetworkType.connected),
      );
      debugPrint('One-off background task registered');
    } catch (e) {
      debugPrint('Error registering one-off task: $e');
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;

    try {
      await Workmanager().cancelAll();
      debugPrint('All background tasks cancelled');
    } catch (e) {
      debugPrint('Error cancelling tasks: $e');
    }
  }
}
