/// Represents a movie show session/timing
class ShowSession {
  final int sessionId;
  final String theatreId;
  final String theatreName;
  final String screenId;
  final String screenName;
  final String movieId;
  final String? movieName;
  final String showDate; // YYYY-MM-DD
  final String showTime; // e.g., "10:00 AM"
  final String? endTime; // e.g., "01:30 PM"
  final String? language;
  final String? format; // 3D, IMAX, ATMOS, etc.
  final int status; // 1 = Available, 2 = Filling, 3 = Sold Out
  final String statusText; // "Available", "Filling Up Fast", "Sold Out"
  final String? statusColor; // Hex color code
  final int totalSeats;
  final int availableSeats;
  final bool hasSubtitle;
  final bool hasHandicap;

  const ShowSession({
    required this.sessionId,
    required this.theatreId,
    required this.theatreName,
    required this.screenId,
    required this.screenName,
    required this.movieId,
    this.movieName,
    required this.showDate,
    required this.showTime,
    this.endTime,
    this.language,
    this.format,
    this.status = 1,
    this.statusText = 'Available',
    this.statusColor,
    this.totalSeats = 0,
    this.availableSeats = 0,
    this.hasSubtitle = false,
    this.hasHandicap = false,
  });

  factory ShowSession.fromJson(
    Map<String, dynamic> json, {
    String? cinemaName,
    String? movieName,
  }) {
    return ShowSession(
      sessionId: json['sessionId'] as int? ?? 0,
      theatreId: json['theatreId']?.toString() ?? '',
      theatreName: cinemaName ?? json['cinemaName'] as String? ?? '',
      screenId: json['screenId']?.toString() ?? '',
      screenName: json['screenName'] as String? ?? '',
      movieId: json['movieId']?.toString() ?? '',
      movieName: movieName ?? json['movieName'] as String?,
      showDate:
          json['showDate'] as String? ?? json['showDateStr'] as String? ?? '',
      showTime: json['showTime'] as String? ?? '',
      endTime: json['endTime'] as String?,
      language: json['language'] as String?,
      format: json['filmFormat'] as String? ?? json['movieFormat'] as String?,
      status: json['status'] as int? ?? 1,
      statusText: json['statusTxt'] as String? ?? 'Available',
      statusColor: json['statusCode'] as String?,
      totalSeats: json['totalSeats'] as int? ?? 0,
      availableSeats: json['availableSeats'] as int? ?? 0,
      hasSubtitle: json['subtitle'] as bool? ?? false,
      hasHandicap: json['handicap'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'theatreId': theatreId,
    'theatreName': theatreName,
    'screenId': screenId,
    'screenName': screenName,
    'movieId': movieId,
    'movieName': movieName,
    'showDate': showDate,
    'showTime': showTime,
    'endTime': endTime,
    'language': language,
    'filmFormat': format,
    'status': status,
    'statusTxt': statusText,
    'statusCode': statusColor,
    'totalSeats': totalSeats,
    'availableSeats': availableSeats,
    'subtitle': hasSubtitle,
    'handicap': hasHandicap,
  };

  /// Is the show available for booking?
  bool get isAvailable =>
      status == 1 || statusText.toLowerCase().contains('available');

  /// Is the show filling up fast?
  bool get isFilling =>
      status == 2 || statusText.toLowerCase().contains('filling');

  /// Is the show sold out?
  bool get isSoldOut =>
      status == 3 || statusText.toLowerCase().contains('sold');

  /// Get seat availability percentage
  double get availabilityPercent {
    if (totalSeats == 0) return 0;
    return (availableSeats / totalSeats) * 100;
  }

  /// Get formatted date string
  String get formattedDate {
    try {
      final parts = showDate.split('-');
      if (parts.length == 3) {
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
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return '${months[month - 1]} $day';
      }
    } catch (_) {}
    return showDate;
  }

  /// Get status emoji
  String get statusEmoji {
    if (isAvailable) return '✅';
    if (isFilling) return '🔥';
    if (isSoldOut) return '❌';
    return '❓';
  }

  /// Get notification title
  String get notificationTitle {
    final movie = movieName ?? 'Movie';
    return '🎬 $movie - $theatreName';
  }

  /// Get notification body
  String get notificationBody {
    final dateTime = '$formattedDate at $showTime';
    final formatStr = format != null && format!.isNotEmpty ? ' ($format)' : '';
    final langStr = language != null && language!.isNotEmpty
        ? ' - $language'
        : '';
    return '$dateTime$formatStr$langStr\nStatus: $statusText ($availableSeats seats)';
  }

  /// Get HTML body for Telegram
  String get htmlBody {
    final movie = movieName ?? 'Movie';
    return '''
🎬 <b>$movie</b>
🏛️ $theatreName
📅 $formattedDate at <b>$showTime</b>
${format != null ? '🎞️ $format' : ''}
${language != null ? '🗣️ $language' : ''}
$statusEmoji <b>$statusText</b> ($availableSeats/$totalSeats seats)
'''
        .trim();
  }

  @override
  String toString() =>
      '$movieName @ $theatreName - $showDate $showTime ($statusText)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShowSession &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}
