import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pvr_data_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../models/monitoring_task.dart';
import 'task_dialog.dart';

/// Tasks tab showing list of monitoring tasks
class TasksTab extends ConsumerWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksProvider);
    final pvrData = ref.watch(pvrDataProvider);

    return Column(
      children: [
        // Toolbar
        _buildToolbar(context, ref, tasksState, pvrData),

        // Tasks list
        Expanded(
          child: tasksState.tasks.isEmpty
              ? _buildEmptyState(context, ref, pvrData)
              : _buildTasksList(context, ref, tasksState),
        ),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    WidgetRef ref,
    TasksState tasksState,
    PvrDataState pvrData,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Add task button
          FilledButton.icon(
            onPressed: pvrData.hasData
                ? () => _showAddTaskDialog(context, ref, pvrData)
                : null,
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),

          const SizedBox(width: 8),

          // Edit button
          OutlinedButton.icon(
            onPressed: tasksState.tasks.isEmpty
                ? null
                : () {
                    _showEditMessage(context);
                  },
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text('Edit'),
          ),

          const Spacer(),

          // Start all button
          if (tasksState.tasks.isNotEmpty) ...[
            FilledButton.tonalIcon(
              onPressed: () => ref.read(tasksProvider.notifier).startAll(),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Start All'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => ref.read(tasksProvider.notifier).stopAll(),
              icon: const Icon(Icons.stop, size: 20),
              label: const Text('Stop All'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
            ),
          ],
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.movie_filter_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Monitoring Tasks',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a task to start monitoring ticket availability\nfor your favorite movies.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: pvrData.hasData
                  ? () => _showAddTaskDialog(context, ref, pvrData)
                  : null,
              icon: const Icon(Icons.add),
              label: Text(
                pvrData.hasData ? 'Add Your First Task' : 'Loading data...',
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: tasksState.tasks.length,
      itemBuilder: (context, index) {
        final task = tasksState.tasks[index];
        final isRunning = tasksState.isTaskRunning(task.id);
        return _TaskCard(
          task: task,
          isRunning: isRunning,
          onToggle: () => ref.read(tasksProvider.notifier).toggleTask(task.id),
          onEdit: () => _showEditTaskDialog(context, ref, task),
          onDelete: () => _confirmDeleteTask(context, ref, task),
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
        content: Text('Remove monitoring for "${task.movieName}"?'),
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

  void _showEditMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap on a task card to edit'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Individual task card widget
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Movie icon with status indicator
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isRunning
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.movie,
                          color: isRunning
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isRunning)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Task info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.movieName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${task.theatreName} • ${task.cityName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    tooltip: 'Delete',
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Bottom row with details and toggle
              Row(
                children: [
                  // Days
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: '${task.days} days',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 8),

                  // Statuses
                  _InfoChip(
                    icon: Icons.check_circle_outline,
                    label: task.statuses.join(', '),
                    colorScheme: colorScheme,
                  ),

                  const Spacer(),

                  // Status text
                  if (isRunning)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Running',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Toggle button
                  FilledButton.icon(
                    onPressed: onToggle,
                    icon: Icon(
                      isRunning ? Icons.stop : Icons.play_arrow,
                      size: 18,
                    ),
                    label: Text(isRunning ? 'Stop' : 'Start'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isRunning
                          ? colorScheme.error
                          : colorScheme.primary,
                      foregroundColor: isRunning
                          ? colorScheme.onError
                          : colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
