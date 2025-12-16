import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/city.dart';
import '../models/movie.dart';
import '../models/theatre.dart';
import '../services/pvr_api_service.dart';

/// State for PVR data (cities, movies, theatres)
class PvrDataState {
  final List<City> cities;
  final List<Movie> movies;
  final List<Theatre> theatres;
  final bool isLoading;
  final String? error;
  final String selectedCity;

  const PvrDataState({
    this.cities = const [],
    this.movies = const [],
    this.theatres = const [],
    this.isLoading = false,
    this.error,
    this.selectedCity = 'Chennai',
  });

  PvrDataState copyWith({
    List<City>? cities,
    List<Movie>? movies,
    List<Theatre>? theatres,
    bool? isLoading,
    String? error,
    String? selectedCity,
  }) {
    return PvrDataState(
      cities: cities ?? this.cities,
      movies: movies ?? this.movies,
      theatres: theatres ?? this.theatres,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCity: selectedCity ?? this.selectedCity,
    );
  }

  bool get hasData => cities.isNotEmpty && movies.isNotEmpty;

  String get statusText {
    if (isLoading) return '🔄 Loading data...';
    if (error != null) return '❌ Error: $error';
    return '✅ Ready | ${cities.length} cities | ${movies.length} movies | ${theatres.length} theatres';
  }
}

/// Notifier for PVR data
class PvrDataNotifier extends StateNotifier<PvrDataState> {
  final PvrApiService _apiService;

  PvrDataNotifier(this._apiService) : super(const PvrDataState());

  /// Load all data (cities, movies, theatres)
  Future<void> loadData({String? cityName}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final city = cityName ?? state.selectedCity;

      // Load cities
      debugPrint('Loading cities...');
      final cities = await _apiService.fetchCities();
      debugPrint('Loaded ${cities.length} cities');

      // Load movies
      debugPrint('Loading movies for $city...');
      final movies = await _apiService.fetchMovies(city);
      debugPrint('Loaded ${movies.length} movies');

      // Load theatres from first movie
      List<Theatre> theatres = [];
      if (movies.isNotEmpty) {
        debugPrint('Loading theatres...');
        final today = DateTime.now();
        final dateStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        theatres = await _apiService.fetchTheatres(
          city,
          movies.first.id,
          dateStr,
        );
        debugPrint('Loaded ${theatres.length} theatres');
      }

      state = state.copyWith(
        cities: cities,
        movies: movies,
        theatres: theatres,
        isLoading: false,
        selectedCity: city,
      );
    } catch (e) {
      debugPrint('Error loading data: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Change selected city and reload movies
  Future<void> changeCity(String cityName) async {
    state = state.copyWith(selectedCity: cityName, isLoading: true);

    try {
      final movies = await _apiService.fetchMovies(cityName);

      List<Theatre> theatres = [];
      if (movies.isNotEmpty) {
        final today = DateTime.now();
        final dateStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        theatres = await _apiService.fetchTheatres(
          cityName,
          movies.first.id,
          dateStr,
        );
      }

      state = state.copyWith(
        movies: movies,
        theatres: theatres,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh theatres for a specific movie
  Future<void> loadTheatresForMovie(String movieId) async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final theatres = await _apiService.fetchTheatres(
        state.selectedCity,
        movieId,
        dateStr,
      );
      state = state.copyWith(theatres: theatres);
    } catch (e) {
      debugPrint('Error loading theatres: $e');
    }
  }
}

/// Provider for PVR API service
final pvrApiServiceProvider = Provider<PvrApiService>((ref) => PvrApiService());

/// Provider for PVR data state
final pvrDataProvider = StateNotifierProvider<PvrDataNotifier, PvrDataState>((
  ref,
) {
  final apiService = ref.watch(pvrApiServiceProvider);
  return PvrDataNotifier(apiService);
});
