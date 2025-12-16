import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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

  // For Android foreground service
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Run monitoring check periodically
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    debugPrint('Background check running...');

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'PVR Cinema Monitor',
          content: 'Checking for ticket availability...',
        );
      }
    }

    await _runMonitoringCheck();

    // Notify that we're still running
    service.invoke('update', {
      'current_date': DateTime.now().toIso8601String(),
    });
  });
}

/// Run monitoring check in background
Future<void> _runMonitoringCheck() async {
  try {
    final storage = StorageService();
    final api = PvrApiService();
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Load tasks
    final tasksJson = storage.getTasks();
    final tasks = MonitoringTask.decodeList(tasksJson);
    final configuredTasks = tasks.where((t) => t.isConfigured).toList();

    debugPrint(
      'Background: Checking ${configuredTasks.length} configured tasks',
    );

    for (final task in configuredTasks) {
      await _checkTask(
        task: task,
        api: api,
        notificationService: notificationService,
        storage: storage,
      );
    }
  } catch (e) {
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
  final timeRange = storage.getTimeRange();

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
          if (storage.getWindowsNotifEnabled()) {
            await notificationService.showNotification(
              title: session.notificationTitle,
              body: session.notificationBody,
            );
            await Future.delayed(const Duration(milliseconds: 500));
          }

          if (storage.getTelegramNotifEnabled()) {
            final botToken = storage.getTelegramBotToken();
            final chatId = storage.getTelegramChatId();
            if (botToken.isNotEmpty && chatId.isNotEmpty) {
              await api.sendTelegramMessage(
                botToken: botToken,
                chatId: chatId,
                message: session.htmlBody,
                parseHtml: true,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking $dateStr: $e');
    }
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
        notificationChannelId: 'pvr_monitor_channel',
        initialNotificationTitle: 'PVR Cinema Monitor',
        initialNotificationContent: 'Monitoring for ticket availability',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
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
    Duration interval = const Duration(minutes: 5),
  }) async {
    if (Platform.isAndroid) {
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
    await _runMonitoringCheck();
  }

  /// Check if service is running (Android)
  Future<bool> isServiceRunning() async {
    if (Platform.isAndroid) {
      return await _service.isRunning();
    }
    return _isRunning;
  }
}
