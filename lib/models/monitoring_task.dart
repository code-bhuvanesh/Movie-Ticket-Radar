import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Monitoring task configuration
class MonitoringTask {
  final String id;

  // City info (optional - user selects)
  final int? cityId;
  final String? cityName;

  // Movie info (optional - user selects)
  final String? movieId;
  final String? movieName;
  final String? moviePoster;

  // Theatre info (optional - null means all theatres)
  final String? theatreId;
  final String? theatreName;

  // Date selection
  final DateSelectionType dateType;
  final List<DateTime>? specificDates; // For specific dates
  final int? daysFromToday; // For range (e.g., next 7 days)
  final DateTime? startDate; // For custom range
  final DateTime? endDate; // For custom range

  // Status filter
  final List<String> statuses;

  // State
  final bool isRunning;
  final DateTime? lastChecked;

  const MonitoringTask({
    String? id,
    this.cityId,
    this.cityName,
    this.movieId,
    this.movieName,
    this.moviePoster,
    this.theatreId,
    this.theatreName,
    this.dateType = DateSelectionType.daysFromToday,
    this.specificDates,
    this.daysFromToday = 7,
    this.startDate,
    this.endDate,
    this.statuses = const ['available', 'filling'],
    this.isRunning = false,
    this.lastChecked,
  }) : id = id ?? '';

  factory MonitoringTask.create({
    int? cityId,
    String? cityName,
    String? movieId,
    String? movieName,
    String? moviePoster,
    String? theatreId,
    String? theatreName,
    DateSelectionType dateType = DateSelectionType.daysFromToday,
    List<DateTime>? specificDates,
    int? daysFromToday = 7,
    DateTime? startDate,
    DateTime? endDate,
    List<String> statuses = const ['available', 'filling'],
  }) {
    return MonitoringTask(
      id: const Uuid().v4(),
      cityId: cityId,
      cityName: cityName,
      movieId: movieId,
      movieName: movieName,
      moviePoster: moviePoster,
      theatreId: theatreId,
      theatreName: theatreName,
      dateType: dateType,
      specificDates: specificDates,
      daysFromToday: daysFromToday,
      startDate: startDate,
      endDate: endDate,
      statuses: statuses,
    );
  }

  MonitoringTask copyWith({
    String? id,
    int? cityId,
    String? cityName,
    String? movieId,
    String? movieName,
    String? moviePoster,
    String? theatreId,
    String? theatreName,
    DateSelectionType? dateType,
    List<DateTime>? specificDates,
    int? daysFromToday,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? statuses,
    bool? isRunning,
    DateTime? lastChecked,
  }) {
    return MonitoringTask(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      movieId: movieId ?? this.movieId,
      movieName: movieName ?? this.movieName,
      moviePoster: moviePoster ?? this.moviePoster,
      theatreId: theatreId ?? this.theatreId,
      theatreName: theatreName ?? this.theatreName,
      dateType: dateType ?? this.dateType,
      specificDates: specificDates ?? this.specificDates,
      daysFromToday: daysFromToday ?? this.daysFromToday,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      statuses: statuses ?? this.statuses,
      isRunning: isRunning ?? this.isRunning,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  factory MonitoringTask.fromJson(Map<String, dynamic> json) {
    return MonitoringTask(
      id: json['id'] as String,
      cityId: json['cityId'] as int?,
      cityName: json['cityName'] as String?,
      movieId: json['movieId'] as String?,
      movieName: json['movieName'] as String?,
      moviePoster: json['moviePoster'] as String?,
      theatreId: json['theatreId'] as String?,
      theatreName: json['theatreName'] as String?,
      dateType: DateSelectionType.values.firstWhere(
        (e) => e.name == json['dateType'],
        orElse: () => DateSelectionType.daysFromToday,
      ),
      specificDates: (json['specificDates'] as List<dynamic>?)
          ?.map((d) => DateTime.parse(d as String))
          .toList(),
      daysFromToday: json['daysFromToday'] as int? ?? 7,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      statuses:
          (json['statuses'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          ['available', 'filling'],
      isRunning: json['isRunning'] as bool? ?? false,
      lastChecked: json['lastChecked'] != null
          ? DateTime.parse(json['lastChecked'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cityId': cityId,
    'cityName': cityName,
    'movieId': movieId,
    'movieName': movieName,
    'moviePoster': moviePoster,
    'theatreId': theatreId,
    'theatreName': theatreName,
    'dateType': dateType.name,
    'specificDates': specificDates?.map((d) => d.toIso8601String()).toList(),
    'daysFromToday': daysFromToday,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'statuses': statuses,
    'isRunning': isRunning,
    'lastChecked': lastChecked?.toIso8601String(),
  };

  /// Get dates to check based on date selection type
  List<DateTime> get datesToCheck {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (dateType) {
      case DateSelectionType.specificDates:
        return specificDates ?? [];

      case DateSelectionType.daysFromToday:
        final days = daysFromToday ?? 7;
        return List.generate(days, (i) => today.add(Duration(days: i)));

      case DateSelectionType.dateRange:
        if (startDate == null || endDate == null) return [];
        final start = DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
        );
        final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
        final days = end.difference(start).inDays + 1;
        return List.generate(days, (i) => start.add(Duration(days: i)));
    }
  }

  /// Get date strings for API calls (YYYY-MM-DD format)
  List<String> get dateStrings {
    return datesToCheck
        .map(
          (d) =>
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        )
        .toList();
  }

  /// Get display name for the task
  String get displayName {
    if (movieName != null && cityName != null) {
      return '$movieName @ ${theatreName ?? cityName}';
    }
    if (movieName != null) return movieName!;
    if (cityName != null) return 'All movies in $cityName';
    return 'Unconfigured Task';
  }

  /// Get date selection description
  String get dateDescription {
    switch (dateType) {
      case DateSelectionType.specificDates:
        final count = specificDates?.length ?? 0;
        return '$count specific date${count != 1 ? 's' : ''}';
      case DateSelectionType.daysFromToday:
        return 'Next ${daysFromToday ?? 7} days';
      case DateSelectionType.dateRange:
        if (startDate != null && endDate != null) {
          return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
        }
        return 'Custom range';
    }
  }

  String _formatDate(DateTime d) {
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

  /// Check if task is properly configured
  bool get isConfigured =>
      cityId != null &&
      cityName != null &&
      movieId != null &&
      movieName != null;

  /// Encode list of tasks to JSON string
  static String encodeList(List<MonitoringTask> tasks) {
    return jsonEncode(tasks.map((t) => t.toJson()).toList());
  }

  /// Decode list of tasks from JSON string
  static List<MonitoringTask> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((t) => MonitoringTask.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonitoringTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// How dates are selected for monitoring
enum DateSelectionType {
  /// Monitor next N days from today
  daysFromToday,

  /// Monitor specific selected dates
  specificDates,

  /// Monitor a date range (start to end)
  dateRange,
}
