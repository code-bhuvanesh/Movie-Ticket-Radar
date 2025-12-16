import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/pvr_data_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/settings_provider.dart';
import 'tasks/tasks_tab.dart';
import 'settings/settings_tab.dart';
import 'logs/logs_tab.dart';

/// Main home screen with navigation bar
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pvrDataProvider.notifier).loadData();
      ref.read(logsProvider.notifier).addLog('🚀 App started');
    });
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pvrData = ref.watch(pvrDataProvider);
    final tasks = ref.watch(tasksProvider);

    final runningCount = tasks.runningTaskIds.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header
            _buildHeader(context, pvrData, runningCount),

            // Content
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [TasksTab(), SettingsTab(), LogsTab()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.task_alt_outlined),
            selectedIcon: const Icon(Icons.task_alt),
            label: 'Tasks',
            tooltip: 'Monitoring Tasks',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
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
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    PvrDataState pvrData,
    int runningCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // App icon and title
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.tertiaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.movie_filter,
                  color: colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PVR Cinema Monitor',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Track ticket availability instantly',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Status indicator
              if (runningCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$runningCount active',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(width: 8),

              // Refresh button
              IconButton.filledTonal(
                onPressed: pvrData.isLoading
                    ? null
                    : () => ref.read(pvrDataProvider.notifier).loadData(),
                icon: pvrData.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh Data',
              ),

              // PVR Website button
              IconButton.filledTonal(
                onPressed: () =>
                    launchUrl(Uri.parse('https://www.pvrcinemas.com')),
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Open PVR Website',
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Data status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: pvrData.error != null
                  ? colorScheme.errorContainer.withValues(alpha: 0.3)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              pvrData.statusText,
              style: TextStyle(
                fontSize: 12,
                color: pvrData.error != null
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
