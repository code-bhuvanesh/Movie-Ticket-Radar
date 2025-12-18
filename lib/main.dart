import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/system_tray_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage first (required for all other services)
  try {
    await StorageService.initialize();
  } catch (e) {
    debugPrint('Error initializing storage: $e');
  }

  // Initialize notifications
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }

  // Debug print stored data
  try {
    StorageService().debugPrintAll();
  } catch (e) {
    debugPrint('Error interacting with storage: $e');
  }

  // Platform-specific initialization
  try {
    if (Platform.isWindows) {
      // Initialize system tray for Windows
      await SystemTrayService().initialize();
    } else if (Platform.isAndroid) {
      // Initialize background service (notification channel is already created above)
      await BackgroundService().initialize();

      // Check if service is already running (e.g., from a previous session)
      final isAlreadyRunning = await BackgroundService().isServiceRunning();
      debugPrint('Background service already running: $isAlreadyRunning');

      if (!isAlreadyRunning) {
        // Start the foreground service for background monitoring
        await BackgroundService().startMonitoring();
        debugPrint('Android background service started');
      } else {
        debugPrint(
          'Background service was already running, not starting again',
        );
      }
    }
  } catch (e) {
    debugPrint('Error initializing platform services: $e');
  }

  runApp(const ProviderScope(child: TicketRadarApp()));
}

class TicketRadarApp extends ConsumerWidget {
  const TicketRadarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Ticket Radar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
