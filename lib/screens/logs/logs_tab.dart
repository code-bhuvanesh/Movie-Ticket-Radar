import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';

/// Logs tab showing activity history
class LogsTab extends ConsumerStatefulWidget {
  const LogsTab({super.key});

  @override
  ConsumerState<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<LogsTab> {
  @override
  void initState() {
    super.initState();
    // Refresh logs from storage when tab opens to pick up background logs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(logsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header & Toolbar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVITY LOGS',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                color: colorScheme.primary,
                              ),
                        ),
                        Text(
                          'Monitor system activity and updates',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHeaderButton(
                          icon: Icons.copy_all,
                          tooltip: 'Copy All',
                          onPressed: () {
                            final text = ref
                                .read(logsProvider.notifier)
                                .allLogsText;
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logs copied')),
                            );
                          },
                          color: colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logs list
          Expanded(
            child: logs.isEmpty
                ? _buildEmptyState(context)
                : _buildLogsList(context, logs),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'refresh_logs',
            onPressed: () {
              ref.read(logsProvider.notifier).refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logs refreshed'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh Logs',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'clear_logs',
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            onPressed: () => _confirmClearLogs(context, ref),
            tooltip: 'Clear History',
            child: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
    );
  }

  void _confirmClearLogs(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs?'),
        content: const Text(
          'This will permanently delete all activity history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              ref.read(logsProvider.notifier).clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logs cleared')));
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'LOGS ARE EMPTY',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, List<String> logs) {
    final colorScheme = Theme.of(context).colorScheme;
    final reversedLogs = logs.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: reversedLogs.length,
      itemBuilder: (context, index) {
        final log = reversedLogs[index];
        final logEntry = _parseLogEntry(log);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                logEntry.timestamp,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  logEntry.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _LogEntry _parseLogEntry(String log) {
    final match = RegExp(r'\[(\d{2}:\d{2}:\d{2})\] (.*)').firstMatch(log);
    if (match != null) {
      return _LogEntry(
        timestamp: match.group(1) ?? '',
        message: match.group(2) ?? log,
      );
    }
    return _LogEntry(timestamp: '', message: log);
  }
}

class _LogEntry {
  final String timestamp;
  final String message;

  _LogEntry({required this.timestamp, required this.message});
}
