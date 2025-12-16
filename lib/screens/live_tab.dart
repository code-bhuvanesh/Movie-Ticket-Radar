import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/live_status_provider.dart';
import '../../models/show_session.dart';

class LiveTab extends ConsumerStatefulWidget {
  const LiveTab({super.key});

  @override
  ConsumerState<LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends ConsumerState<LiveTab> {
  @override
  void initState() {
    super.initState();
    // Auto-refresh when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveStatusProvider.notifier).refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Availability',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Real-time status of your tasks',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: liveState.isLoading
                      ? null
                      : () =>
                            ref.read(liveStatusProvider.notifier).refreshAll(),
                  icon: liveState.isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),

          if (liveState.error != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      liveState.error!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: liveState.taskStatuses.isEmpty && !liveState.isLoading
                ? _buildEmptyState(context, colorScheme)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: liveState.taskStatuses.length,
                    itemBuilder: (context, index) {
                      final status = liveState.taskStatuses[index];
                      // Only show if it has sessions or error
                      if (status.sessions.isEmpty && status.error == null) {
                        return const SizedBox.shrink();
                      }

                      return _LiveTaskCard(status: status);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_seat_outlined,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Available Sessions Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your task settings or refresh',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTaskCard extends StatelessWidget {
  final TaskLiveStatus status;

  const _LiveTaskCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final task = status.task;

    // Filter to only show relevant sessions if we have any, otherwise show all
    final relevantSessions = status.sessions
        .where((s) => s.isAvailable || s.isFilling)
        .toList();
    final displaySessions = relevantSessions.isNotEmpty
        ? relevantSessions
        : status.sessions;

    // Limit to 5 sessions to avoid huge lists
    final limitedSessions = displaySessions.take(5).toList();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (task.moviePoster != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      task.moviePoster!,
                      width: 30,
                      height: 45,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.movieName ?? 'Unknown Movie',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        task.theatreName ?? task.cityName ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (relevantSessions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'AVAILABLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Sessions List
            if (status.error != null)
              Text(
                'Error: ${status.error}',
                style: TextStyle(color: colorScheme.error),
              )
            else if (limitedSessions.isEmpty)
              Text(
                'No matching shows found based on your filters.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...limitedSessions.map(
                (session) => _SessionRow(session: session),
              ),

            if (displaySessions.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '+ ${displaySessions.length - 5} more sessions',
                    style: TextStyle(fontSize: 12, color: colorScheme.primary),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    launchUrl(Uri.parse('https://www.pvrcinemas.com')),
                child: const Text('Book on PVR Website'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final ShowSession session;

  const _SessionRow({required this.session});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine color based on status
    Color statusColor = colorScheme.outline;
    if (session.isAvailable)
      statusColor = Colors.green;
    else if (session.isFilling)
      statusColor = Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              session.showTime,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),

          // Date
          Text(
            session.formattedDate, // e.g., Jan 15
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(width: 12),

          // Show Status Text
          Expanded(
            child: Text(
              session.statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
