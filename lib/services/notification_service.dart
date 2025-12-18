import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';

/// Top-level callback for handling notification responses in background isolates
@pragma('vm:entry-point')
void notificationTappedBackground(NotificationResponse response) {
  debugPrint('Background notification tapped: ${response.payload}');
  // Note: In background isolate, we can't directly update UI state
  // The payload will be handled when the app is opened
}

/// Service for handling platform-specific notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final ValueNotifier<String?> selectedPayload = ValueNotifier(null);

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isInitializedForBackground = false;

  /// Initialize the notification service for background use only
  /// This is a lightweight initialization for the background isolate
  Future<void> initializeForBackground() async {
    if (_isInitializedForBackground) return;

    try {
      if (Platform.isAndroid) {
        const androidSettings = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const initSettings = InitializationSettings(android: androidSettings);

        await _flutterLocalNotificationsPlugin.initialize(
          initSettings,
          onDidReceiveNotificationResponse: notificationTappedBackground,
          onDidReceiveBackgroundNotificationResponse:
              notificationTappedBackground,
        );

        // Create notification channel in background too (required for Android 8.0+)
        await createAlertNotificationChannel();

        debugPrint('Android notification support initialized for background');
      }

      _isInitializedForBackground = true;
    } catch (e) {
      debugPrint('Error initializing notifications for background: $e');
    }
  }

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Platform.isAndroid) {
        const androidSettings = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const initSettings = InitializationSettings(android: androidSettings);

        await _flutterLocalNotificationsPlugin.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
          onDidReceiveBackgroundNotificationResponse:
              notificationTappedBackground,
        );

        final details = await _flutterLocalNotificationsPlugin
            .getNotificationAppLaunchDetails();
        if (details != null &&
            details.didNotificationLaunchApp &&
            details.notificationResponse != null) {
          _onNotificationTapped(details.notificationResponse!);
        }

        await _requestAndroidPermissions();

        // Create notification channels BEFORE the service starts
        await createBackgroundServiceChannel();
        await createAlertNotificationChannel();

        debugPrint('Android notification support initialized');
      } else if (Platform.isWindows) {
        // Initialize local_notifier for Windows
        await localNotifier.setup(
          appName: 'Ticket Radar',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
        debugPrint('Windows notification support initialized');
      }

      _isInitialized = true;
      debugPrint('NotificationService initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Create the notification channel for the background service (Android 13+ requirement)
  Future<void> createBackgroundServiceChannel() async {
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          'ticket_radar_channel', // Must match the ID in BackgroundService
          'Ticket Radar Service',
          description: 'Background service for monitoring ticket availability',
          importance: Importance
              .low, // Low importance for persistent service notification
          playSound: false,
          enableVibration: false,
        );
        await androidPlugin.createNotificationChannel(channel);
        debugPrint('Background service notification channel created');
      }
    } catch (e) {
      debugPrint('Error creating background service channel: $e');
    }
  }

  /// Create the notification channel for ticket alerts (with sound)
  Future<void> createAlertNotificationChannel() async {
    if (!Platform.isAndroid) return;

    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          'ticket_alerts_channel', // Separate channel for alerts
          'Ticket Alerts',
          description: 'Notifications when tickets become available',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
        debugPrint('Alert notification channel created');
      }
    } catch (e) {
      debugPrint('Error creating alert notification channel: $e');
    }
  }

  // Request notification permissions (Android 13+)
  Future<void> _requestAndroidPermissions() async {
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('Notification permission granted: $granted');

        if (granted != true) {
          debugPrint('WARNING: Notification permission was NOT granted!');
        }
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    selectedPayload.value = response.payload ?? 'live_tab';
  }

  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    // Ensure we're initialized (either for foreground or background)
    if (!_isInitialized && !_isInitializedForBackground) {
      await initializeForBackground();
    }

    try {
      if (Platform.isAndroid) {
        await _showAndroidNotification(
          title: title,
          body: body,
          payload: payload,
          id: id,
        );
      } else if (Platform.isWindows) {
        await _showWindowsNotification(title: title, body: body);
      } else {
        debugPrint('[NOTIF] Notification: $title - $body');
      }
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Show Android notification
  Future<void> _showAndroidNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    final notificationId =
        id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

    debugPrint('Preparing Android notification ID: $notificationId');

    final androidDetails = AndroidNotificationDetails(
      'ticket_alerts_channel', // Use the alerts channel (with sound)
      'Ticket Alerts',
      channelDescription: 'Notifications when tickets become available',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Ticket Radar',
      ),
      ticker: title,
      autoCancel: true,
      ongoing: false,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      debugPrint(
        'Android notification shown successfully: $title (ID: $notificationId)',
      );
    } catch (e) {
      debugPrint('Error in _flutterLocalNotificationsPlugin.show: $e');
      rethrow;
    }
  }

  /// Show Windows notification using local_notifier
  Future<void> _showWindowsNotification({
    required String title,
    required String body,
  }) async {
    try {
      final notification = LocalNotification(title: title, body: body);

      notification.onShow = () {
        debugPrint('Windows notification shown: $title');
      };

      notification.onClose = (reason) {
        debugPrint('Windows notification closed: $reason');
      };

      notification.onClick = () {
        debugPrint('Windows notification clicked: $title');
        selectedPayload.value = 'live_tab';
      };

      await notification.show();
    } catch (e) {
      debugPrint('Error showing Windows notification: $e');
      // Fallback to debug print
      debugPrint('[NOTIF] Windows Notification: $title - $body');
    }
  }

  /// Show multiple notifications for found shows
  Future<void> showTicketNotifications(
    List<Map<String, String>> tickets,
  ) async {
    for (int i = 0; i < tickets.length && i < 5; i++) {
      final ticket = tickets[i];
      await showNotification(
        title: ticket['title'] ?? 'Tickets Available!',
        body: ticket['body'] ?? '',
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000) + i,
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    try {
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin.cancelAll();
      }
      // local_notifier doesn't have cancelAll, notifications auto-dismiss
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    try {
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin.cancel(id);
      }
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }
}
