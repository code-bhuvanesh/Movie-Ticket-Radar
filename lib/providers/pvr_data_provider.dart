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
  final City? selectedCity; // null by default - user must select
  final Movie? selectedMovie; // null by default - user must select
  final bool isLoading;
  final String? error;
  final double? userLatitude;
  final double? userLongitude;

  const PvrDataState({
    this.cities = const [],
    this.movies = const [],
    this.theatres = const [],
    this.selectedCity,
    this.selectedMovie,
    this.isLoading = false,
    this.error,
    this.userLatitude,
    this.userLongitude,
  });

  PvrDataState copyWith({
    List<City>? cities,
    List<Movie>? movies,
    List<Theatre>? theatres,
    City? selectedCity,
    Movie? selectedMovie,
    bool? isLoading,
    String? error,
    double? userLatitude,
    double? userLongitude,
    bool clearSelectedCity = false,
    bool clearSelectedMovie = false,
    bool clearError = false,
  }) {
    return PvrDataState(
      cities: cities ?? this.cities,
      movies: movies ?? this.movies,
      theatres: theatres ?? this.theatres,
      selectedCity: clearSelectedCity
          ? null
          : (selectedCity ?? this.selectedCity),
      selectedMovie: clearSelectedMovie
          ? null
          : (selectedMovie ?? this.selectedMovie),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
    );
  }

  bool get hasData => cities.isNotEmpty;
  bool get hasMovies => movies.isNotEmpty;
  bool get hasTheatres => theatres.isNotEmpty;
  bool get hasCitySelected => selectedCity != null;
  bool get hasMovieSelected => selectedMovie != null;

  /// Get cities sorted by distance from user
  List<City> get citiesByDistance {
    if (userLatitude != null && userLongitude != null) {
      return City.sortByDistance(cities, userLatitude!, userLongitude!);
    }
    return cities;
  }

  /// Get nearest city
  City? get nearestCity {
    final sorted = citiesByDistance;
    return sorted.isNotEmpty ? sorted.first : null;
  }

  String get statusText {
    if (isLoading) return 'Loading...';
    if (error != null) return 'Error: $error';
    final parts = <String>[];
    if (cities.isNotEmpty) parts.add('${cities.length} cities');
    if (movies.isNotEmpty) parts.add('${movies.length} movies');
    if (theatres.isNotEmpty) parts.add('${theatres.length} theatres');
    if (parts.isEmpty) return 'No data loaded';
    return parts.join(' | ');
  }
}

/// Notifier for PVR data
class PvrDataNotifier extends StateNotifier<PvrDataState> {
  final PvrApiService _apiService;

  PvrDataNotifier(this._apiService) : super(const PvrDataState());

  /// Set user location for distance-based sorting
  void setUserLocation(double latitude, double longitude) {
    state = state.copyWith(userLatitude: latitude, userLongitude: longitude);
  }

  /// Load cities
  Future<void> loadCities() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('Loading cities...');
      final cities = await _apiService.fetchCities();
      debugPrint('Loaded ${cities.length} cities');
      state = state.copyWith(cities: cities, isLoading: false);
    } catch (e) {
      debugPrint('Error loading cities: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Select a city and load its movies
  Future<void> selectCity(City city) async {
    state = state.copyWith(
      selectedCity: city,
      clearSelectedMovie: true, // Clear movie when city changes
      movies: [],
      theatres: [],
      isLoading: true,
    );

    try {
      debugPrint('Loading movies for ${city.name}...');

      // Fetch both now showing and coming soon movies
      final results = await Future.wait([
        _apiService.fetchNowShowing(city.name),
        _apiService.fetchComingSoon(city.name),
      ]);

      final nowShowing = results[0];
      final comingSoon = results[1];

      // Combine and dedup based on ID
      final Map<String, Movie> movieMap = {};
      for (final m in nowShowing) {
        movieMap[m.id] = m;
      }
      for (final m in comingSoon) {
        if (!movieMap.containsKey(m.id)) {
          movieMap[m.id] = m;
        }
      }

      final allMovies = movieMap.values.toList();

      debugPrint(
        'Loaded ${allMovies.length} movies (Showing: ${nowShowing.length}, Upcoming: ${comingSoon.length})',
      );
      state = state.copyWith(movies: allMovies, isLoading: false);
    } catch (e) {
      debugPrint('Error loading movies: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Select a movie and load theatres
  Future<void> selectMovie(Movie movie) async {
    if (state.selectedCity == null) {
      state = state.copyWith(error: 'Please select a city first');
      return;
    }

    state = state.copyWith(selectedMovie: movie, theatres: [], isLoading: true);

    try {
      debugPrint(
        'Loading theatres for ${movie.name} in ${state.selectedCity!.name}...',
      );
      // Use cinemas API to get all theatres in the city
      final theatres = await _apiService.fetchCinemas(
        cityName: state.selectedCity!.name,
      );
      debugPrint('Loaded ${theatres.length} theatres');
      state = state.copyWith(theatres: theatres, isLoading: false);
    } catch (e) {
      debugPrint('Error loading theatres: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Clear city selection
  void clearCity() {
    state = state.copyWith(
      clearSelectedCity: true,
      clearSelectedMovie: true,
      movies: [],
      theatres: [],
    );
  }

  /// Clear movie selection
  void clearMovie() {
    state = state.copyWith(clearSelectedMovie: true, theatres: []);
  }

  /// Load all data (cities first, then movies if city is selected)
  Future<void> loadData() async {
    await loadCities();
  }

  /// Reload movies for current city
  Future<void> reloadMovies() async {
    if (state.selectedCity != null) {
      await selectCity(state.selectedCity!);
    }
  }

  /// Legacy method for backward compatibility
  Future<void> changeCity(String cityName) async {
    final city = state.cities.where((c) => c.name == cityName).firstOrNull;
    if (city != null) {
      await selectCity(city);
    }
  }

  /// Legacy method for backward compatibility
  Future<void> loadTheatresForMovie(String movieId) async {
    final movie = state.movies.where((m) => m.id == movieId).firstOrNull;
    if (movie != null) {
      await selectMovie(movie);
    }
  }
}

/// Provider for PVR data
final pvrDataProvider = StateNotifierProvider<PvrDataNotifier, PvrDataState>((
  ref,
) {
  return PvrDataNotifier(PvrApiService());
});
