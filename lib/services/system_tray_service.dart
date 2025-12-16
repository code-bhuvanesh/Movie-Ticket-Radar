import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Service for managing Windows system tray
class SystemTrayService with TrayListener, WindowListener {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  bool _isInitialized = false;
  bool _isQuitting = false;

  /// Callback when user wants to show the window
  VoidCallback? onShowWindow;

  /// Callback when user wants to quit the app
  VoidCallback? onQuitApp;

  /// Callback when starting all tasks
  VoidCallback? onStartAllTasks;

  /// Callback when stopping all tasks
  VoidCallback? onStopAllTasks;

  /// Initialize system tray (Windows only)
  Future<void> initialize() async {
    if (!Platform.isWindows || _isInitialized) return;

    try {
      // Initialize window manager
      await windowManager.ensureInitialized();

      // Set up window options
      final windowOptions = WindowOptions(
        minimumSize: const Size(400, 600),
        size: const Size(500, 800),
        center: true,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'PVR Cinema Monitor',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      // Set prevent close to intercept close event
      await windowManager.setPreventClose(true);

      // Add window listener to intercept close
      windowManager.addListener(this);

      // Initialize tray - use absolute path for Windows
      String iconPath;
      if (Platform.isWindows) {
        // Get the executable directory
        final exePath = Platform.resolvedExecutable;
        final exeDir = exePath.substring(
          0,
          exePath.lastIndexOf(Platform.pathSeparator),
        );
        iconPath = '$exeDir\\data\\flutter_assets\\assets\\app_icon.ico';
        debugPrint('Tray icon path: $iconPath');
      } else {
        iconPath = 'assets/app_icon.png';
      }

      await trayManager.setIcon(iconPath);

      await trayManager.setToolTip('PVR Cinema Monitor');

      // Create context menu
      final menu = Menu(
        items: [
          MenuItem(key: 'show_app', label: 'Show App'),
          MenuItem.separator(),
          MenuItem(key: 'start_all', label: 'Start All Tasks'),
          MenuItem(key: 'stop_all', label: 'Stop All Tasks'),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: 'Exit'),
        ],
      );

      await trayManager.setContextMenu(menu);

      // Add tray listener
      trayManager.addListener(this);

      _isInitialized = true;
      debugPrint('System tray initialized');
    } catch (e) {
      debugPrint('Error initializing system tray: $e');
    }
  }

  /// Update tray tooltip with status
  Future<void> updateTooltip(String status) async {
    if (!_isInitialized) return;
    try {
      await trayManager.setToolTip('PVR Cinema Monitor\n$status');
    } catch (e) {
      debugPrint('Error updating tooltip: $e');
    }
  }

  /// Show the main window
  Future<void> showWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setSkipTaskbar(false);
      onShowWindow?.call();
    } catch (e) {
      debugPrint('Error showing window: $e');
    }
  }

  /// Hide to system tray
  Future<void> hideToTray() async {
    if (!Platform.isWindows) return;
    try {
      await windowManager.hide();
      debugPrint('Window hidden to tray');
    } catch (e) {
      debugPrint('Error hiding to tray: $e');
    }
  }

  /// Quit the application
  Future<void> quitApp() async {
    _isQuitting = true;
    try {
      await trayManager.destroy();
      await windowManager.destroy();
    } catch (e) {
      debugPrint('Error quitting app: $e');
      exit(0);
    }
  }

  /// Check if we're in the process of quitting
  bool get isQuitting => _isQuitting;

  /// Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
      await trayManager.destroy();
    }
  }

  // TrayListener implementation
  @override
  void onTrayIconMouseDown() {
    // Show window on left click
    showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    // Show context menu on right click
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_app':
        showWindow();
        break;
      case 'start_all':
        onStartAllTasks?.call();
        break;
      case 'stop_all':
        onStopAllTasks?.call();
        break;
      case 'exit':
        quitApp();
        break;
    }
  }

  @override
  void onTrayIconMouseUp() {}

  @override
  void onTrayIconRightMouseUp() {}

  // WindowListener implementation
  @override
  void onWindowClose() async {
    // Instead of closing, hide to tray
    if (!_isQuitting) {
      await hideToTray();
    }
  }

  @override
  void onWindowFocus() {}

  @override
  void onWindowBlur() {}

  @override
  void onWindowMaximize() {}

  @override
  void onWindowUnmaximize() {}

  @override
  void onWindowMinimize() {}

  @override
  void onWindowRestore() {}

  @override
  void onWindowResize() {}

  @override
  void onWindowMove() {}

  @override
  void onWindowEnterFullScreen() {}

  @override
  void onWindowLeaveFullScreen() {}

  @override
  void onWindowEvent(String eventName) {}

  @override
  void onWindowMoved() {}

  @override
  void onWindowResized() {}

  @override
  void onWindowDocked() {}

  @override
  void onWindowUndocked() {}
}
