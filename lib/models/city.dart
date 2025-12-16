/// City model representing a PVR city
class City {
  final int id;
  final String name;
  final String? region;
  final String? state;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final int cinemaCount;
  final bool hasSubCities;
  final List<SubCity> subCities;

  const City({
    required this.id,
    required this.name,
    this.region,
    this.state,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.cinemaCount = 0,
    this.hasSubCities = false,
    this.subCities = const [],
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int,
      name: json['name'] as String,
      region: json['region'] as String?,
      state: json['state'] as String?,
      latitude: _parseDouble(json['lat']),
      longitude: _parseDouble(json['lng']),
      imageUrl: json['image'] as String?,
      cinemaCount: json['cinemaCount'] as int? ?? 0,
      hasSubCities: json['hasSubCities'] as bool? ?? false,
      subCities:
          (json['subcities'] as List<dynamic>?)
              ?.map((s) => SubCity.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'region': region,
    'state': state,
    'lat': latitude?.toString(),
    'lng': longitude?.toString(),
    'image': imageUrl,
    'cinemaCount': cinemaCount,
    'hasSubCities': hasSubCities,
    'subcities': subCities.map((s) => s.toJson()).toList(),
  };

  /// Calculate distance from given coordinates (in km)
  double? distanceFrom(double lat, double lng) {
    if (latitude == null || longitude == null) return null;

    // Haversine formula
    const double earthRadius = 6371; // km
    final dLat = _toRadians(latitude! - lat);
    final dLng = _toRadians(longitude! - lng);

    final a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat)) *
            _cos(_toRadians(latitude!)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  /// Sort cities by distance from given coordinates
  static List<City> sortByDistance(List<City> cities, double lat, double lng) {
    final sorted = List<City>.from(cities);
    sorted.sort((a, b) {
      final distA = a.distanceFrom(lat, lng);
      final distB = b.distanceFrom(lat, lng);
      if (distA == null && distB == null) return 0;
      if (distA == null) return 1;
      if (distB == null) return -1;
      return distA.compareTo(distB);
    });
    return sorted;
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Math helpers (avoiding dart:math import for cleaner code)
  static double _toRadians(double deg) => deg * 3.14159265359 / 180;
  static double _sin(double x) => _taylor(x, true);
  static double _cos(double x) => _taylor(x, false);
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x / 2;
    for (int i = 0; i < 10; i++) {
      g = (g + x / g) / 2;
    }
    return g;
  }

  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (y > 0) return 3.14159265359 / 2;
    if (y < 0) return -3.14159265359 / 2;
    return 0;
  }

  static double _atan(double x) {
    double sum = 0;
    double term = x;
    for (int n = 0; n < 20; n++) {
      sum += term / (2 * n + 1);
      term *= -x * x;
    }
    return sum;
  }

  static double _taylor(double x, bool isSin) {
    x = x % (2 * 3.14159265359);
    double sum = isSin ? x : 1;
    double term = isSin ? x : 1;
    for (int n = 1; n < 15; n++) {
      term *= -x * x / ((2 * n + (isSin ? 1 : 0)) * (2 * n + (isSin ? 0 : -1)));
      sum += term;
    }
    return sum;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Sub-city model for cities with multiple sub-locations (like Delhi-NCR)
class SubCity {
  final int id;
  final String name;

  const SubCity({required this.id, required this.name});

  factory SubCity.fromJson(Map<String, dynamic> json) {
    return SubCity(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  String toString() => name;
}
