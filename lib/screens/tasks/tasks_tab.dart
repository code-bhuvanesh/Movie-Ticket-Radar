import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pvr_data_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../models/monitoring_task.dart';
import 'task_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tasks tab showing list of monitoring tasks
class TasksTab extends ConsumerWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksProvider);
    final pvrData = ref.watch(pvrDataProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, ref, pvrData, tasksState.runningTaskIds.length),
          Expanded(
            child: tasksState.tasks.isEmpty
                ? _buildEmptyState(context, ref, pvrData)
                : _buildTasksList(context, ref, tasksState),
          ),
        ],
      ),
      floatingActionButton: tasksState.tasks.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: pvrData.hasData
                  ? () => _showAddTaskDialog(context, ref, pvrData)
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            )
          : null,
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    PvrDataState pvrData,
    int runningCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TICKET RADAR',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Cinema Ticket Tracker',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (runningCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$runningCount LIVE',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: pvrData.isLoading
                ? null
                : () => ref.read(pvrDataProvider.notifier).loadData(),
            icon: pvrData.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
          IconButton(
            onPressed: () => launchUrl(
              Uri.parse('https://www.pvrcinemas.com'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.language),
            tooltip: 'Cinema Website',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    PvrDataState pvrData,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.movie_filter_outlined,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Start Your Watchlist',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Track tickets for your favorite upcoming\nmovies and get notified instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: pvrData.hasData
                  ? () => _showAddTaskDialog(context, ref, pvrData)
                  : null,
              icon: const Icon(Icons.add),
              label: Text(
                pvrData.hasData
                    ? 'Create Monitoring Task'
                    : 'Loading Cinema Data...',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(
    BuildContext context,
    WidgetRef ref,
    TasksState tasksState,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 600,
              mainAxisExtent: 230, // Fixed height for TaskCard
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: tasksState.tasks.length,
            itemBuilder: (context, index) {
              final task = tasksState.tasks[index];
              final isRunning = tasksState.isTaskRunning(task.id);
              return _TaskCard(
                task: task,
                isRunning: isRunning,
                onToggle: () =>
                    ref.read(tasksProvider.notifier).toggleTask(task.id),
                onEdit: () => _showEditTaskDialog(context, ref, task),
                onDelete: () => _confirmDeleteTask(context, ref, task),
              );
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          itemCount: tasksState.tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final task = tasksState.tasks[index];
            final isRunning = tasksState.isTaskRunning(task.id);
            return _TaskCard(
              task: task,
              isRunning: isRunning,
              onToggle: () =>
                  ref.read(tasksProvider.notifier).toggleTask(task.id),
              onEdit: () => _showEditTaskDialog(context, ref, task),
              onDelete: () => _confirmDeleteTask(context, ref, task),
            );
          },
        );
      },
    );
  }

  void _showAddTaskDialog(
    BuildContext context,
    WidgetRef ref,
    PvrDataState pvrData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => TaskDialog(
        cities: pvrData.cities,
        movies: pvrData.movies,
        theatres: pvrData.theatres,
        onSave: (task) {
          ref.read(tasksProvider.notifier).addTask(task);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditTaskDialog(
    BuildContext context,
    WidgetRef ref,
    MonitoringTask task,
  ) {
    final pvrData = ref.read(pvrDataProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) => TaskDialog(
        cities: pvrData.cities,
        movies: pvrData.movies,
        theatres: pvrData.theatres,
        existingTask: task,
        onSave: (updatedTask) {
          ref.read(tasksProvider.notifier).updateTask(updatedTask);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmDeleteTask(
    BuildContext context,
    WidgetRef ref,
    MonitoringTask task,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete Task?'),
        content: Text('Remove monitoring for "${task.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(tasksProvider.notifier).removeTask(task.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Cinematic task card widget
class _TaskCard extends StatelessWidget {
  final MonitoringTask task;
  final bool isRunning;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.isRunning,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConfigured = task.isConfigured;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Main Content Row (Poster + Info)
            Positioned.fill(
              bottom: 40, // Reserve space for date bar
              child: Row(
                children: [
                  // Left Side: Poster
                  SizedBox(
                    width: 140,
                    height: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildPoster(colorScheme),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                colorScheme.surfaceContainer,
                                colorScheme.surfaceContainer.withValues(
                                  alpha: 0.0,
                                ),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right Side: Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Badge & Menu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatusBadge(colorScheme, isConfigured),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: onEdit,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.edit,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: onDelete,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.delete,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Movie Title
                          Text(
                            task.movieName ?? 'Select Movie',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // Location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.theatreName ??
                                      task.cityName ??
                                      'Select Location',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Controls (Moved above the date bar)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isConfigured ? onToggle : null,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                    ),
                                    side: BorderSide(
                                      color: isRunning
                                          ? colorScheme.error.withValues(
                                              alpha: 0.5,
                                            )
                                          : colorScheme.primary.withValues(
                                              alpha: 0.5,
                                            ),
                                    ),
                                    foregroundColor: isRunning
                                        ? colorScheme.error
                                        : colorScheme.primary,
                                    minimumSize: const Size(0, 42),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isRunning ? 'STOP' : 'START MONITORING',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Date Bar Overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: _buildDateBarContent(context, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(ColorScheme colorScheme) {
    if (task.moviePoster != null) {
      return Image.network(
        task.moviePoster!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.movie,
            size: 40,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.movie,
        size: 40,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildStatusBadge(ColorScheme colorScheme, bool isConfigured) {
    if (!isConfigured) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'INCOMPLETE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: colorScheme.onErrorContainer,
          ),
        ),
      );
    }

    if (isRunning) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 6,
              height: 6,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'LIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    // Static badge for scheduled/paused
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'PAUSED',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDateBarContent(BuildContext context, ColorScheme colorScheme) {
    if (task.dateType == DateSelectionType.specificDates &&
        task.specificDates != null &&
        task.specificDates!.isNotEmpty) {
      return Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.calendar_today,
              size: 14,
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              itemCount: task.specificDates!.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDateShort(task.specificDates![index]),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      );
    }

    // For ranges or days from today
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(
            task.dateType == DateSelectionType.daysFromToday
                ? Icons.update
                : Icons.date_range,
            size: 16,
            color: colorScheme.primary.withValues(alpha: 0.9),
          ),
        ),
        Text(
          task.dateDescription, // e.g. "Next 7 days"
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  String _formatDateShort(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
