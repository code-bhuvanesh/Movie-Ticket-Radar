import 'dart:convert';
import 'package:flutter/foundation.dart';
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
            final Set<int> cityIds = {};

            // Current city first (if available)
            final currentCity = output['cc'] as Map<String, dynamic>?;
            if (currentCity != null) {
              final c = City.fromJson(currentCity);
              cityIds.add(c.id);
              cities.add(c);
            }

            // Popular cities
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
      debugPrint('Error fetching cities: $e');
      throw Exception('Failed to fetch cities: $e');
    }
  }

  /// Fetch now-showing movies for a city
  Future<List<Movie>> fetchNowShowing(String cityName) async {
    try {
      final headers = Map<String, String>.from(ApiConstants.headers);
      headers['city'] = cityName;

      debugPrint('Fetching movies for city: $cityName');

      final response = await http
          .post(
            Uri.parse(ApiConstants.apiNowShowing),
            headers: headers,
            body: jsonEncode({'city': cityName}),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('Movies API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['result'] == 'success') {
          final output = data['output'] as Map<String, dynamic>?;
          if (output != null) {
            final mvList = output['mv'] as List<dynamic>? ?? [];
            final movies = mvList
                .map((m) => Movie.fromJson(m as Map<String, dynamic>))
                .toList();
            debugPrint('Parsed ${movies.length} movies');
            return movies;
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching movies: $e');
      throw Exception('Failed to fetch movies: $e');
    }
  }

  /// Alias for backward compatibility
  Future<List<Movie>> fetchMovies(String cityName) => fetchNowShowing(cityName);

  /// Fetch cinemas/theatres for a city using the cinemas API
  Future<List<Theatre>> fetchCinemas({
    required String cityName,
    String? lat,
    String? lng,
  }) async {
    try {
      final headers = Map<String, String>.from(ApiConstants.headers);
      headers['city'] = cityName;

      final payload = {
        'city': cityName,
        'lat': lat ?? ApiConstants.defaultLat,
        'lng': lng ?? ApiConstants.defaultLng,
        'text': '',
      };

      debugPrint('Fetching cinemas for city: $cityName');

      final response = await http
          .post(
            Uri.parse(ApiConstants.apiCinemas),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('Cinemas API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['result'] == 'success') {
          final output = data['output'] as Map<String, dynamic>?;
          if (output != null) {
            final cinemaList = output['c'] as List<dynamic>? ?? [];
            debugPrint('Found ${cinemaList.length} cinemas');

            final theatres = cinemaList.map((c) {
              return Theatre.fromCinemaJson(c as Map<String, dynamic>);
            }).toList();

            debugPrint('Parsed ${theatres.length} theatres');
            return theatres;
          }
        } else {
          debugPrint('Cinemas API error: ${data['msg']}');
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching cinemas: $e');
      throw Exception('Failed to fetch cinemas: $e');
    }
  }

  /// Fetch theatres for a movie (uses msessions API)
  Future<List<Theatre>> fetchTheatres({
    required String cityName,
    required String movieId,
    required String movieName,
    String? date,
  }) async {
    try {
      final headers = Map<String, String>.from(ApiConstants.headers);
      headers['city'] = cityName;

      // Use today if no date specified
      final now = DateTime.now();
      final dateStr =
          date ??
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      debugPrint(
        'Fetching theatres for movie: $movieName (id: $movieId) on $dateStr',
      );

      final payload = {
        'city': cityName,
        'mid': movieId,
        'dated': dateStr,
        'experience': 'ALL',
        'specialTag': 'ALL',
        'lat': ApiConstants.defaultLat,
        'lng': ApiConstants.defaultLng,
        'lang': 'ALL',
        'format': 'ALL',
        'time': ApiConstants.defaultTimeRange,
        'cinetype': 'ALL',
        'hc': 'ALL',
        'adFree': false,
      };

      debugPrint('Payload: $payload');

      final response = await http
          .post(
            Uri.parse(ApiConstants.apiSessions),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('Theatres API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('API result: ${data['result']}');

        if (data['result'] == 'success') {
          final output = data['output'] as Map<String, dynamic>?;
          if (output != null) {
            final sessions =
                output['movieCinemaSessions'] as List<dynamic>? ?? [];
            debugPrint('Found ${sessions.length} cinema sessions');

            final theatres = sessions.map((s) {
              final cinema =
                  (s as Map<String, dynamic>)['cinema']
                      as Map<String, dynamic>? ??
                  {};
              return Theatre.fromJson(cinema);
            }).toList();

            debugPrint('Parsed ${theatres.length} theatres');
            return theatres;
          }
        } else {
          debugPrint('API error: ${data['msg']}');
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching theatres: $e');
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

      debugPrint('Fetching sessions for: $movieName (id: $movieId) on $date');

      final payload = {
        'city': cityName,
        'mid': movieId,
        'dated': date,
        'experience': 'ALL',
        'specialTag': 'ALL',
        'lat': ApiConstants.defaultLat,
        'lng': ApiConstants.defaultLng,
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
            final String? movieCommonId =
                output['movie']?['id']?.toString() ?? movieId;

            final cinemaSessions =
                output['movieCinemaSessions'] as List<dynamic>? ?? [];

            for (final cinemaSession in cinemaSessions) {
              final cs = cinemaSession as Map<String, dynamic>;
              final cinema = cs['cinema'] as Map<String, dynamic>? ?? {};
              final cinemaId = cinema['theatreId']?.toString() ?? '';
              final cinemaName = cinema['name']?.toString() ?? '';

              // Filter by theatre if specified
              if (theatreId != null && cinemaId != theatreId) continue;

              final experienceSessions =
                  cs['experienceSessions'] as List<dynamic>? ?? [];

              for (final expSession in experienceSessions) {
                final es = expSession as Map<String, dynamic>;
                final shows = es['shows'] as List<dynamic>? ?? [];

                for (final show in shows) {
                  final showData = show as Map<String, dynamic>;
                  final session = ShowSession.fromJson(
                    showData,
                    movieName: movieName,
                    cinemaName: cinemaName,
                    cityName: cityName,
                    movieId: movieCommonId,
                  );

                  // Debug session status
                  debugPrint(
                    'Session: ${session.showTime} @ $cinemaName - Status: ${session.statusText} (${session.status}) - Available: ${session.isAvailable}',
                  );

                  sessions.add(session);
                }
              }
            }
          }
        }
      }

      debugPrint('Total sessions found: ${sessions.length}');
      return sessions;
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      throw Exception('Failed to fetch sessions: $e');
    }
  }
}
