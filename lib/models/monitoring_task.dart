import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Monitoring task model for tracking movie ticket availability
class MonitoringTask {
  final String id;
  final String cityId;
  final String cityName;
  final String movieId;
  final String movieName;
  final String? theatreId;
  final String theatreName;
  final int days;
  final List<String> statuses; // 'available', 'filling'
  bool isRunning;
  DateTime? lastChecked;

  MonitoringTask({
    String? id,
    required this.cityId,
    required this.cityName,
    required this.movieId,
    required this.movieName,
    this.theatreId,
    this.theatreName = 'All Theatres',
    this.days = 7,
    this.statuses = const ['available', 'filling'],
    this.isRunning = false,
    this.lastChecked,
  }) : id = id ?? const Uuid().v4();

  factory MonitoringTask.fromJson(Map<String, dynamic> json) {
    return MonitoringTask(
      id: json['id']?.toString(),
      cityId: json['city_id']?.toString() ?? json['cityId']?.toString() ?? '',
      cityName:
          json['city_name']?.toString() ?? json['cityName']?.toString() ?? '',
      movieId:
          json['movie_id']?.toString() ?? json['movieId']?.toString() ?? '',
      movieName:
          json['movie_name']?.toString() ?? json['movieName']?.toString() ?? '',
      theatreId:
          json['theatre_id']?.toString() ?? json['theatreId']?.toString(),
      theatreName:
          json['theatre_name']?.toString() ??
          json['theatreName']?.toString() ??
          'All Theatres',
      days: json['days'] as int? ?? 7,
      statuses:
          (json['statuses'] as List<dynamic>?)?.cast<String>() ??
          ['available', 'filling'],
      isRunning:
          json['is_running'] as bool? ?? json['isRunning'] as bool? ?? false,
      lastChecked: json['lastChecked'] != null
          ? DateTime.tryParse(json['lastChecked'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cityId': cityId,
    'cityName': cityName,
    'movieId': movieId,
    'movieName': movieName,
    'theatreId': theatreId,
    'theatreName': theatreName,
    'days': days,
    'statuses': statuses,
    'isRunning': isRunning,
    'lastChecked': lastChecked?.toIso8601String(),
  };

  MonitoringTask copyWith({
    String? id,
    String? cityId,
    String? cityName,
    String? movieId,
    String? movieName,
    String? theatreId,
    String? theatreName,
    int? days,
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
      theatreId: theatreId ?? this.theatreId,
      theatreName: theatreName ?? this.theatreName,
      days: days ?? this.days,
      statuses: statuses ?? this.statuses,
      isRunning: isRunning ?? this.isRunning,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  String get displayName =>
      movieName.length > 25 ? '${movieName.substring(0, 25)}...' : movieName;

  String get statusText => isRunning ? '🟢 Running' : '⬚ Stopped';

  static String encodeList(List<MonitoringTask> tasks) {
    return jsonEncode(tasks.map((t) => t.toJson()).toList());
  }

  static List<MonitoringTask> decodeList(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => MonitoringTask.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonitoringTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
