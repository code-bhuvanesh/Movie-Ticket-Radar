import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/settings_provider.dart';

/// Logs tab showing activity history
class LogsTab extends ConsumerWidget {
  const LogsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider);

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  ref.read(logsProvider.notifier).clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logs cleared'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.delete_sweep, size: 20),
                label: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final text = ref.read(logsProvider.notifier).allLogsText;
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logs copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  ref.read(logsProvider.notifier).addLog('📋 Logs copied');
                },
                icon: const Icon(Icons.copy, size: 20),
                label: const Text('Copy'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () =>
                    launchUrl(Uri.parse('https://www.pvrcinemas.com')),
                icon: const Icon(Icons.open_in_new, size: 20),
                label: const Text('PVR Website'),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Logs Yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Activity logs will appear here',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, List<String> logs) {
    final colorScheme = Theme.of(context).colorScheme;

    // Reverse to show newest first
    final reversedLogs = logs.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: reversedLogs.length,
      itemBuilder: (context, index) {
        final log = reversedLogs[index];
        final logEntry = _parseLogEntry(log);

        return Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: index.isEven
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  logEntry.timestamp,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Message
              Expanded(
                child: Text(
                  logEntry.message,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _LogEntry _parseLogEntry(String log) {
    // Format: [HH:MM:SS] message
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
