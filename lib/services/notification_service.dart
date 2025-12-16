import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';

/// Service for handling platform-specific notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

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
        );

        await _requestAndroidPermissions();
        debugPrint('Android notification support initialized');
      } else if (Platform.isWindows) {
        // Initialize local_notifier for Windows
        await localNotifier.setup(
          appName: 'PVR Cinema Monitor',
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

  Future<void> _requestAndroidPermissions() async {
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (!_isInitialized) await initialize();

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
        debugPrint('🔔 Notification: $title - $body');
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
    const androidDetails = AndroidNotificationDetails(
      'pvr_monitor_channel',
      'PVR Monitor',
      channelDescription: 'Ticket availability notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    debugPrint('Android notification shown: $title');
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
      };

      await notification.show();
    } catch (e) {
      debugPrint('Error showing Windows notification: $e');
      // Fallback to debug print
      debugPrint('🔔 Windows Notification: $title - $body');
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
