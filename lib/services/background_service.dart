import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../services/pvr_api_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../models/monitoring_task.dart';

/// Entry point for Android background service (must be top-level)
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  debugPrint('Background service started');

  // Initialize storage
  await StorageService.initialize();

  // Log startup
  await _addBackgroundLog('[START] Background service started');

  // For Android foreground service
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Stop service listener
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Listener for immediate check requests from UI
  service.on('runCheck').listen((event) async {
    await _addBackgroundLog('[INPUT] Immediate check requested from UI');
    await _runMonitoringCheck();
  });

  // Run an immediate check on startup
  if (service is AndroidServiceInstance) {
    if (await service.isForegroundService()) {
      service.setForegroundNotificationInfo(
        title: 'Ticket Radar',
        content: 'Background monitoring active',
      );
    }
  }

  await _addBackgroundLog('[RUN] Running initial background check...');
  await _runMonitoringCheck();
  await _addBackgroundLog('[IDLE] Background check completed. Idle for 15m.');

  // Keep-alive timer (logs every 5 minutes to prove service is alive without heavy API usage)
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    debugPrint('[$timestamp] Background service keep-alive ping');
  });

  // Run monitoring check periodically (every 15 minutes)
  Timer.periodic(const Duration(minutes: 15), (timer) async {
    await _addBackgroundLog('[TIMER] Periodic check triggered');

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'Ticket Radar',
          content: 'Checking for ticket availability...',
        );
      }
    }

    await _runMonitoringCheck();
    await _addBackgroundLog('[IDLE] Check completed. Idle for 15m.');

    // Notify that we're still running
    service.invoke('update', {
      'current_date': DateTime.now().toIso8601String(),
    });
  });
}

/// Add a log entry from the background service to persistent storage
Future<void> _addBackgroundLog(String message) async {
  try {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    await StorageService().addLog(logEntry);
    debugPrint('Background log: $logEntry');
  } catch (e) {
    debugPrint('Error adding background log: $e');
  }
}

/// Run monitoring check in background
Future<void> _runMonitoringCheck() async {
  try {
    final storage = StorageService();
    final api = PvrApiService();
    final notificationService = NotificationService();
    // Use background-specific initialization for the isolated service context
    await notificationService.initializeForBackground();

    // Reload storage to see changes from main isolate
    await storage.reload();

    // Save the time of this check
    await storage.setLastBackgroundRun(DateTime.now());

    // Load tasks
    final tasksJson = storage.getTasks();
    final tasks = MonitoringTask.decodeList(tasksJson);
    final configuredTasks = tasks.where((t) => t.isConfigured).toList();

    await _addBackgroundLog(
      '[CHECK] Checking ${configuredTasks.length} configured tasks',
    );

    for (final task in configuredTasks) {
      await _checkTask(
        task: task,
        api: api,
        notificationService: notificationService,
        storage: storage,
      );
    }

    await _addBackgroundLog('[DONE] All configured tasks checked');
  } catch (e) {
    await _addBackgroundLog('[ERROR] Background check error: $e');
    debugPrint('Background check error: $e');
  }
}

/// Check a single task
Future<void> _checkTask({
  required MonitoringTask task,
  required PvrApiService api,
  required NotificationService notificationService,
  required StorageService storage,
}) async {
  if (!task.isConfigured) return;

  final dateStrings = task.dateStrings;
  const timeRange = ApiConstants.defaultTimeRange;

  // Check if debug mode bypasses notification cache
  final forceNotify = storage.getDebugForceNotify();

  // Get already notified sessions to avoid duplicates (unless force notify is on)
  final notifiedSessions = forceNotify
      ? <String>{}
      : storage.getNotifiedSessions();

  // Collect ALL matching sessions across all dates (that haven't been notified yet)
  final List<String> matchingSummaries = [];
  final List<String> newSessionKeys = [];

  for (final dateStr in dateStrings) {
    try {
      await Future.delayed(const Duration(seconds: 2));

      final sessions = await api.fetchSessions(
        cityName: task.cityName!,
        movieId: task.movieId!,
        movieName: task.movieName!,
        date: dateStr,
        timeRange: timeRange,
        theatreId: task.theatreId,
      );

      for (final session in sessions) {
        bool matches = false;
        if (task.statuses.contains('available') && session.isAvailable) {
          matches = true;
        }
        if (task.statuses.contains('filling') && session.isFilling) {
          matches = true;
        }

        if (matches) {
          // Create a unique key for this session
          final sessionKey =
              '${task.id}_${session.theatreId}_${session.showTime}_$dateStr';

          // Only add if not already notified
          if (!notifiedSessions.contains(sessionKey)) {
            matchingSummaries.add(
              '${session.showTime} - ${session.statusText}',
            );
            newSessionKeys.add(sessionKey);
          }
        }
      }
    } catch (e) {
      await _addBackgroundLog('[WARN] Error checking $dateStr: $e');
      debugPrint('Error checking $dateStr: $e');
    }
  }

  // Send ONE notification if there are any NEW matching sessions
  if (matchingSummaries.isNotEmpty) {
    final title = '[MOVIE] ${task.movieName}';
    final body = matchingSummaries.length <= 3
        ? matchingSummaries.join('\n')
        : '${matchingSummaries.take(3).join('\n')}\n+${matchingSummaries.length - 3} more shows';

    await _addBackgroundLog(
      '[FOUND] Found ${matchingSummaries.length} shows for ${task.movieName}!',
    );

    if (storage.getWindowsNotifEnabled()) {
      await notificationService.showNotification(title: title, body: body);
      await _addBackgroundLog(
        '[NOTIF] Notification sent for ${task.movieName}',
      );
    }

    // Mark these sessions as notified to prevent duplicates
    await storage.addNotifiedSessions(newSessionKeys);
    debugPrint(
      'Notified ${newSessionKeys.length} new sessions for task ${task.id}',
    );
  } else {
    await _addBackgroundLog('[NONE] ${task.movieName}: No new tickets found');
  }
}

/// Service for managing background monitoring tasks
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Timer? _monitorTimer;
  bool _isRunning = false;
  final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Check if background monitoring is running
  bool get isRunning => _isRunning;

  /// Initialize background service
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      await _initializeAndroidService();
    }
    debugPrint('Background service initialized');
  }

  /// Initialize Android foreground service
  Future<void> _initializeAndroidService() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'ticket_radar_channel',
        initialNotificationTitle: 'Ticket Radar',
        initialNotificationContent: 'Monitoring for ticket availability',
        foregroundServiceNotificationId: 888,
        // Use specialUse type to avoid timeout restrictions on Android 15+
        foregroundServiceTypes: [AndroidForegroundType.specialUse],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: (service) => true,
      ),
    );
  }

  /// Start background monitoring
  Future<void> startMonitoring({
    Duration interval = const Duration(minutes: 15),
  }) async {
    if (Platform.isAndroid) {
      // Check if service is already running
      final alreadyRunning = await _service.isRunning();
      if (alreadyRunning) {
        debugPrint('Android foreground service already running, syncing state');
        _isRunning = true;
        return;
      }

      // Start the Android foreground service
      await _service.startService();
      _isRunning = true;
      debugPrint('Android foreground service started');
    } else {
      // For Windows, use timer-based approach
      if (_isRunning) return;

      _isRunning = true;
      debugPrint('Starting timer-based monitoring');

      await _runForegroundCheck();

      _monitorTimer = Timer.periodic(interval, (timer) async {
        await _runForegroundCheck();
      });
    }
  }

  /// Stop background monitoring
  Future<void> stopMonitoring() async {
    if (Platform.isAndroid) {
      _service.invoke('stopService');
    }
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isRunning = false;
    debugPrint('Background monitoring stopped');
  }

  /// Run a check in the foreground (for Windows or immediate checks)
  Future<void> _runForegroundCheck() async {
    await _runMonitoringCheck();
  }

  /// Run a single check immediately
  Future<void> runOnce() async {
    if (Platform.isAndroid && await _service.isRunning()) {
      _service.invoke('runCheck');
    } else {
      await _runMonitoringCheck();
    }
  }

  /// Check if service is running (Android)
  Future<bool> isServiceRunning() async {
    if (Platform.isAndroid) {
      return await _service.isRunning();
    }
    return _isRunning;
  }

  /// Request battery optimization exemption (important for Android 12+)
  /// This opens the system settings to let the user disable battery optimization
  Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return true;

    try {
      // Open the battery optimization settings list
      // Users will need to find the app in the list and set to "Unrestricted"
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );
      await intent.launch();
      debugPrint('Opened battery optimization settings');
      return true;
    } catch (e) {
      debugPrint('Error opening battery optimization settings: $e');

      // Fallback: Try to open app-specific settings
      try {
        const appIntent = AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:com.example.ticket_radar',
        );
        await appIntent.launch();
        debugPrint('Opened app details settings');
        return true;
      } catch (e2) {
        debugPrint('Error opening app settings: $e2');
        return false;
      }
    }
  }

  /// Open app settings for manual permission configuration
  Future<bool> openAppSettings() async {
    if (!Platform.isAndroid) return false;

    try {
      const intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
        data: 'package:com.example.pvr_monitor',
      );
      await intent.launch();
      return true;
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }
}
