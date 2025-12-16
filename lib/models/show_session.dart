/// Show session model representing a movie showtime
class ShowSession {
  final String showId;
  final String movieName;
  final String cinemaName;
  final String cinemaId;
  final String showTime;
  final String date;
  final String status;
  final String? experience;
  final String? format;
  final String? language;

  const ShowSession({
    required this.showId,
    required this.movieName,
    required this.cinemaName,
    required this.cinemaId,
    required this.showTime,
    required this.date,
    required this.status,
    this.experience,
    this.format,
    this.language,
  });

  factory ShowSession.fromJson(
    Map<String, dynamic> json, {
    required String movieName,
    required String date,
    required Map<String, dynamic> cinema,
    String? experience,
  }) {
    return ShowSession(
      showId: json['showId']?.toString() ?? '',
      movieName: movieName,
      cinemaName: cinema['name']?.toString() ?? 'Unknown',
      cinemaId: cinema['theatreId']?.toString() ?? '',
      showTime: json['showTime']?.toString() ?? '',
      date: date,
      status: json['statusTxt']?.toString() ?? '',
      experience: experience,
      format: json['filmFormat']?.toString(),
      language: json['lang']?.toString(),
    );
  }

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isFilling => status.toLowerCase().contains('filling');

  String get notificationTitle => '🎬 $movieName';

  String get notificationBody =>
      '''$cinemaName
$date at $showTime
${format ?? ''} ${experience ?? ''}
Status: $status''';

  String get htmlBody =>
      '''🎬 <b>$movieName</b>
🏛️ $cinemaName
📅 $date at $showTime
🎞️ ${format ?? ''} ${experience ?? ''}
🎯 $status''';

  @override
  String toString() => '$movieName @ $cinemaName - $date $showTime ($status)';
}
