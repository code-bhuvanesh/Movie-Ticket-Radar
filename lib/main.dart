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
  await StorageService.initialize();

  // Initialize notifications
  await NotificationService().initialize();

  // Debug print stored data
  StorageService().debugPrintAll();

  // Platform-specific initialization
  if (Platform.isWindows) {
    // Initialize system tray for Windows
    await SystemTrayService().initialize();
  } else if (Platform.isAndroid) {
    // Initialize background service for Android
    await BackgroundService().initialize();
  }

  runApp(const ProviderScope(child: PvrMonitorApp()));
}

class PvrMonitorApp extends ConsumerWidget {
  const PvrMonitorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'PVR Cinema Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
