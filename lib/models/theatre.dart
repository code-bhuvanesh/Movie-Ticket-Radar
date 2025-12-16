/// Theatre/Cinema model representing a PVR cinema location
class Theatre {
  final String theatreId;
  final String name;
  final String cityName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? distance; // e.g., "3.4 km away"
  final double? distanceKm;
  final String? imageVertical; // miv
  final String? imageHorizontal; // mih
  final bool hasHandicap;
  final bool hasFoodDelivery;
  final bool hasVakaao; // Group booking
  final int screenCount;
  final List<Screen> screens;

  const Theatre({
    required this.theatreId,
    required this.name,
    required this.cityName,
    this.address,
    this.latitude,
    this.longitude,
    this.distance,
    this.distanceKm,
    this.imageVertical,
    this.imageHorizontal,
    this.hasHandicap = false,
    this.hasFoodDelivery = false,
    this.hasVakaao = false,
    this.screenCount = 0,
    this.screens = const [],
  });

  factory Theatre.fromJson(Map<String, dynamic> json) {
    // Parse screens if available
    List<Screen> screens = [];
    if (json['screens'] != null) {
      final screensMap = json['screens'] as Map<String, dynamic>;
      screens = screensMap.entries
          .map((e) => Screen.fromJson(e.value as Map<String, dynamic>))
          .toList();
    }

    return Theatre(
      theatreId: json['theatreId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      cityName: json['cityName'] as String? ?? json['city'] as String? ?? '',
      address: json['address1'] as String? ?? json['address'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distance: json['distanceText'] as String?,
      distanceKm: _parseDouble(json['distance'])?.let((d) => d / 1000),
      imageVertical: json['miv'] as String?,
      imageHorizontal: json['mih'] as String?,
      hasHandicap: json['handicap'] as bool? ?? false,
      hasFoodDelivery: json['fbDeliveryOnSeat'] as bool? ?? false,
      hasVakaao: json['vakaao'] as bool? ?? json['vakaoo'] as bool? ?? false,
      screenCount: screens.length,
      screens: screens,
    );
  }

  /// Factory for parsing cinema from the /cinemas API response
  factory Theatre.fromCinemaJson(Map<String, dynamic> json) {
    // Parse screens if available
    List<Screen> screens = [];
    if (json['screens'] != null) {
      final screensData = json['screens'];
      if (screensData is Map<String, dynamic>) {
        screens = screensData.entries
            .map((e) => Screen.fromJson(e.value as Map<String, dynamic>))
            .toList();
      }
    }

    // Parse distance - it's in meters in cinemas API
    double? distanceKm;
    final distance = json['distance'];
    if (distance != null) {
      if (distance is int) {
        distanceKm = distance / 1000;
      } else if (distance is double) {
        distanceKm = distance / 1000;
      }
    }

    return Theatre(
      theatreId: json['theatreId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      address: json['address1'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distance: json['distanceText'] as String?,
      distanceKm: distanceKm,
      imageVertical: json['miv'] as String?,
      imageHorizontal: json['mih'] as String?,
      hasHandicap: json['handicap'] as bool? ?? false,
      hasFoodDelivery: json['fbDeliveryOnSeat'] as bool? ?? false,
      hasVakaao: json['vakaao'] as bool? ?? false,
      screenCount: screens.length,
      screens: screens,
    );
  }

  Map<String, dynamic> toJson() => {
    'theatreId': theatreId,
    'name': name,
    'cityName': cityName,
    'address1': address,
    'latitude': latitude?.toString(),
    'longitude': longitude?.toString(),
    'distanceText': distance,
    'distance': distanceKm?.let((d) => (d * 1000).round()),
    'miv': imageVertical,
    'mih': imageHorizontal,
    'handicap': hasHandicap,
    'fbDeliveryOnSeat': hasFoodDelivery,
    'vakaao': hasVakaao,
    'screens': {for (var s in screens) s.screenId.toString(): s.toJson()},
  };

  /// Get image URL (prefer vertical)
  String? get imageUrl => imageVertical ?? imageHorizontal;

  /// Get short address (first part before comma)
  String? get shortAddress {
    if (address == null) return null;
    final parts = address!.split(',');
    return parts.first.trim();
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Theatre &&
          runtimeType == other.runtimeType &&
          theatreId == other.theatreId;

  @override
  int get hashCode => theatreId.hashCode;

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Screen/Audi within a theatre
class Screen {
  final int screenId;
  final String name;
  final String? type; // Premium, BIGPIX, IMAX, etc.
  final bool hasHandicap;
  final bool hasVakaao;

  const Screen({
    required this.screenId,
    required this.name,
    this.type,
    this.hasHandicap = false,
    this.hasVakaao = false,
  });

  factory Screen.fromJson(Map<String, dynamic> json) {
    return Screen(
      screenId: json['screenId'] as int? ?? 0,
      name: json['screenName'] as String? ?? '',
      type: json['screenType'] as String?,
      hasHandicap: json['handicap'] as bool? ?? false,
      hasVakaao: json['vakaao'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'screenId': screenId,
    'screenName': name,
    'screenType': type,
    'handicap': hasHandicap,
    'vakaao': hasVakaao,
  };

  @override
  String toString() => name;
}

/// Extension for nullable transform
extension _NullableExtension<T> on T? {
  R? let<R>(R Function(T) transform) {
    if (this == null) return null;
    return transform(this as T);
  }
}
