import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pvr_data_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/background_service.dart';
import '../services/storage_service.dart';
import 'tasks/tasks_tab.dart';
import 'settings/settings_tab.dart';
import 'logs/logs_tab.dart';
import 'live_tab.dart';
import '../providers/live_status_provider.dart';

/// Main home screen with navigation bar
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  static const String _permissionAskedKey = 'battery_permission_asked';

  @override
  void initState() {
    super.initState();
    // Load data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pvrDataProvider.notifier).loadData();
      ref.read(logsProvider.notifier).addLog('[START] App started');

      // Check if we opened via notification (if payload is already set)
      if (NotificationService.selectedPayload.value != null) {
        setState(() => _selectedIndex = 1);
      }

      // Listen for future notification taps
      NotificationService.selectedPayload.addListener(() {
        final payload = NotificationService.selectedPayload.value;
        if (payload != null && mounted) {
          setState(() => _selectedIndex = 1); // Switch to Live tab
        }
      });

      // Show permission dialog on Android if not shown before
      if (Platform.isAndroid) {
        _checkAndRequestPermissions();
      }
    });
  }

  /// Check and request necessary permissions for background service
  Future<void> _checkAndRequestPermissions() async {
    final storage = StorageService();
    final hasAsked = storage.prefs.getBool(_permissionAskedKey) ?? false;

    if (!hasAsked) {
      // Wait a bit for the UI to settle
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await _showBatteryOptimizationDialog();
        await storage.prefs.setBool(_permissionAskedKey, true);
      }
    }
  }

  /// Show dialog explaining battery optimization
  Future<void> _showBatteryOptimizationDialog() async {
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.battery_saver, color: colorScheme.primary, size: 48),
        title: const Text('Enable Background Monitoring'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For reliable ticket monitoring, please disable battery optimization for this app:',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _buildPermissionStep('1', 'Open App Settings'),
            _buildPermissionStep('2', 'Go to Battery'),
            _buildPermissionStep('3', 'Select "Unrestricted"'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Without this, Android may stop the background service to save battery.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await BackgroundService().requestBatteryOptimizationExemption();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStep(String number, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // If Live tab is selected, trigger refresh
    if (index == 1) {
      ref.read(liveStatusProvider.notifier).refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);

    final runningCount = tasks.runningTaskIds.length;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWindows = Platform.isWindows;

          if (isWindows) {
            return Row(
              children: [
                // Side Navigation (Windows Style)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: 0.0,
                  destinations: _buildRailDestinations(runningCount),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Icon(
                      Icons.movie_filter,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  ),
                ),
                VerticalDivider(
                  thickness: 1,
                  width: 1,
                  color: Theme.of(context).dividerTheme.color,
                ),
                // Main Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: const [
                      TasksTab(),
                      LiveTab(),
                      SettingsTab(),
                      LogsTab(),
                    ],
                  ),
                ),
              ],
            );
          }

          // Mobile Layout (Bottom Nav for both Portrait & Landscape)
          return SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [TasksTab(), LiveTab(), SettingsTab(), LogsTab()],
            ),
          );
        },
      ),
      bottomNavigationBar: !Platform.isWindows
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: _buildBarDestinations(runningCount),
            )
          : null,
    );
  }

  List<NavigationDestination> _buildBarDestinations(int runningCount) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.task_alt_outlined),
        selectedIcon: Icon(Icons.task_alt),
        label: 'Tasks',
        tooltip: 'Monitoring Tasks',
      ),
      const NavigationDestination(
        icon: Icon(Icons.live_tv_outlined),
        selectedIcon: Icon(Icons.live_tv),
        label: 'Live',
        tooltip: 'Live Availability',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
        tooltip: 'App Settings',
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: runningCount > 0,
          label: Text('$runningCount'),
          child: const Icon(Icons.receipt_long_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: runningCount > 0,
          label: Text('$runningCount'),
          child: const Icon(Icons.receipt_long),
        ),
        label: 'Logs',
        tooltip: 'Activity Logs',
      ),
    ];
  }

  List<NavigationRailDestination> _buildRailDestinations(int runningCount) {
    return [
      const NavigationRailDestination(
        icon: Icon(Icons.task_alt_outlined),
        selectedIcon: Icon(Icons.task_alt),
        label: Text('Tasks'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.live_tv_outlined),
        selectedIcon: Icon(Icons.live_tv),
        label: Text('Live'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
      NavigationRailDestination(
        icon: Badge(
          isLabelVisible: runningCount > 0,
          label: Text('$runningCount'),
          child: const Icon(Icons.receipt_long_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: runningCount > 0,
          label: Text('$runningCount'),
          child: const Icon(Icons.receipt_long),
        ),
        label: const Text('Logs'),
      ),
    ];
  }
}
