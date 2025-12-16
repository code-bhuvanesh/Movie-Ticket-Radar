import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/city.dart';
import '../models/movie.dart';
import '../models/theatre.dart';
import '../models/show_session.dart';

/// Service for making PVR Cinema API calls
class PvrApiService {
  static final PvrApiService _instance = PvrApiService._internal();
  factory PvrApiService() => _instance;
  PvrApiService._internal();

  /// Fetch all available cities
  Future<List<City>> fetchCities() async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.apiCities),
            headers: ApiConstants.headers,
            body: jsonEncode({}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['result'] == 'success') {
          final output = data['output'] as Map<String, dynamic>?;
          if (output != null) {
            final List<City> cities = [];
            final Set<String> cityIds = {};

            // Popular cities first
            final popular = output['pc'] as List<dynamic>? ?? [];
            for (final city in popular) {
              final c = City.fromJson(city as Map<String, dynamic>);
              if (!cityIds.contains(c.id)) {
                cityIds.add(c.id);
                cities.add(c);
              }
            }

            // Other cities
            final others = output['ot'] as List<dynamic>? ?? [];
            for (final city in others) {
              final c = City.fromJson(city as Map<String, dynamic>);
              if (!cityIds.contains(c.id)) {
                cityIds.add(c.id);
                cities.add(c);
              }
            }

            return cities;
          }
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch cities: $e');
    }
  }

  /// Fetch now-showing movies for a city
  Future<List<Movie>> fetchMovies(String cityName) async {
    try {
      final headers = Map<String, String>.from(ApiConstants.headers);
      headers['city'] = cityName;

      final response = await http
          .post(
            Uri.parse(ApiConstants.apiNowShowing),
            headers: headers,
            body: jsonEncode({'city': cityName}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['result'] == 'success') {
          final output = data['output'] as Map<String, dynamic>?;
          if (output != null) {
            final mvList = output['mv'] as List<dynamic>? ?? [];
            return mvList
                .map((m) => Movie.fromJson(m as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch movies: $e');
    }
  }

  /// Fetch theatres for a movie (uses the first movie if movieId is null)
  Future<List<Theatre>> fetchTheatres(
    String cityName,
    String movieId,
    String date,
  ) async {
    try {
      final headers = Map<String, String>.from(ApiConstants.headers);
      headers['city'] = cityName;

      final payload = {
        'city': cityName,
        'mid': movieId,
        'dated': date,
        'experience': 'ALL',
        'specialTag': 'ALL',
        'lat': '12.89231',
        'lng': '80.23172',
        'lang': 'ALL',
        'format': 'ALL',
        'time': ApiConstants.defaultTimeRange,
        'cinetype': 'ALL',
        'hc': 'ALL',
        'adFree': false,
      };

      final response = await http
          .post(
            Uri.parse(ApiConstants.apiSessions),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['result'] == 'success') {
          final output = data['output'] as Map<String, dynamic>?;
          if (output != null) {
            final sessions =
                output['movieCinemaSessions'] as List<dynamic>? ?? [];
            return sessions.map((s) {
              final cinema =
                  (s as Map<String, dynamic>)['cinema']
                      as Map<String, dynamic>? ??
                  {};
              return Theatre.fromJson(cinema);
            }).toList();
          }
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch theatres: $e');
    }
  }

  /// Fetch show sessions for a movie on a specific date
  Future<List<ShowSession>> fetchSessions({
    required String cityName,
    required String movieId,
    required String movieName,
    required String date,
    required String timeRange,
    String? theatreId,
  }) async {
    try {
      final headers = Map<String, String>.from(ApiConstants.headers);
      headers['city'] = cityName;

      final payload = {
        'city': cityName,
        'mid': movieId,
        'dated': date,
        'experience': 'ALL',
        'specialTag': 'ALL',
        'lat': '12.89231',
        'lng': '80.23172',
        'lang': 'ALL',
        'format': 'ALL',
        'time': timeRange,
        'cinetype': 'ALL',
        'hc': 'ALL',
        'adFree': false,
      };

      final response = await http
          .post(
            Uri.parse(ApiConstants.apiSessions),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      final List<ShowSession> sessions = [];

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['result'] == 'success') {
          final output = data['output'] as Map<String, dynamic>?;
          if (output != null) {
            final cinemaSessions =
                output['movieCinemaSessions'] as List<dynamic>? ?? [];

            for (final cinemaSession in cinemaSessions) {
              final cs = cinemaSession as Map<String, dynamic>;
              final cinema = cs['cinema'] as Map<String, dynamic>? ?? {};
              final cinemaId = cinema['theatreId']?.toString() ?? '';

              // Filter by theatre if specified
              if (theatreId != null && cinemaId != theatreId) continue;

              final experienceSessions =
                  cs['experienceSessions'] as List<dynamic>? ?? [];

              for (final expSession in experienceSessions) {
                final es = expSession as Map<String, dynamic>;
                final experience = es['experience']?.toString();
                final shows = es['shows'] as List<dynamic>? ?? [];

                for (final show in shows) {
                  final session = ShowSession.fromJson(
                    show as Map<String, dynamic>,
                    movieName: movieName,
                    date: date,
                    cinema: cinema,
                    experience: experience,
                  );
                  sessions.add(session);
                }
              }
            }
          }
        }
      }

      return sessions;
    } catch (e) {
      throw Exception('Failed to fetch sessions: $e');
    }
  }

  /// Send a test message to Telegram
  Future<bool> sendTelegramMessage({
    required String botToken,
    required String chatId,
    required String message,
    bool parseHtml = false,
  }) async {
    try {
      final url = '${ApiConstants.telegramApiBase}$botToken/sendMessage';
      final payload = {
        'chat_id': chatId,
        'text': message,
        if (parseHtml) 'parse_mode': 'HTML',
      };

      final response = await http
          .post(Uri.parse(url), body: payload)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
