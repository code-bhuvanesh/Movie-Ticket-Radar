import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/pvr_api_service.dart';

import '../models/show_session.dart';
import '../models/monitoring_task.dart';
import 'tasks_provider.dart';

/// State for the Live Status tab
class LiveStatusState {
  final bool isLoading;
  final List<TaskLiveStatus> taskStatuses;
  final String? error;

  LiveStatusState({
    this.isLoading = false,
    this.taskStatuses = const [],
    this.error,
  });

  LiveStatusState copyWith({
    bool? isLoading,
    List<TaskLiveStatus>? taskStatuses,
    String? error,
  }) {
    return LiveStatusState(
      isLoading: isLoading ?? this.isLoading,
      taskStatuses: taskStatuses ?? this.taskStatuses,
      error: error,
    );
  }
}

/// Represents the live status of a single monitoring task
class TaskLiveStatus {
  final MonitoringTask task;
  final List<ShowSession> sessions;
  final String? error;
  final DateTime lastUpdated;

  TaskLiveStatus({
    required this.task,
    required this.sessions,
    this.error,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  bool get hasAvailableSessions =>
      sessions.any((s) => s.isAvailable || s.isFilling);
}

final liveStatusProvider =
    StateNotifierProvider<LiveStatusNotifier, LiveStatusState>((ref) {
      return LiveStatusNotifier(ref);
    });

class LiveStatusNotifier extends StateNotifier<LiveStatusState> {
  final Ref _ref;
  final PvrApiService _apiService = PvrApiService();

  LiveStatusNotifier(this._ref) : super(LiveStatusState());

  /// Refresh specific tasks or all if configured
  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tasks = _ref.read(tasksProvider).configuredTasks;
      final List<TaskLiveStatus> results = [];

      for (final task in tasks) {
        try {
          // If detailed specific theatre task
          final sessions = await _fetchTaskSessions(task);
          results.add(TaskLiveStatus(task: task, sessions: sessions));
        } catch (e) {
          results.add(
            TaskLiveStatus(task: task, sessions: [], error: e.toString()),
          );
        }
      }

      state = state.copyWith(isLoading: false, taskStatuses: results);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<ShowSession>> _fetchTaskSessions(MonitoringTask task) async {
    final List<ShowSession> allSessions = [];
    final timeRange = ApiConstants.defaultTimeRange;

    for (final dateStr in task.dateStrings) {
      final sessions = await _apiService.fetchSessions(
        cityName: task.cityName!,
        movieId: task.movieId!,
        movieName: task.movieName!,
        date: dateStr,
        timeRange: timeRange,
        theatreId: task.theatreId,
      );
      allSessions.addAll(sessions);
    }

    // Sort by boolean available/filling first, then by time
    allSessions.sort((a, b) {
      final aRelevant = a.isAvailable || a.isFilling;
      final bRelevant = b.isAvailable || b.isFilling;
      if (aRelevant && !bRelevant) return -1;
      if (!aRelevant && bRelevant) return 1;
      return a.showTime.compareTo(b.showTime);
    });

    return allSessions;
  }
}
