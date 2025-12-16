/// Movie model representing a PVR movie
class Movie {
  final String id;
  final String name;
  final String? posterVertical; // miv - vertical poster
  final String? posterHorizontal; // mih - horizontal poster
  final String? backdropImage;
  final String? runtime; // mlength (e.g., "2h 30m")
  final String? synopsis;
  final String? director;
  final String? starring;
  final String? certificate; // ce (e.g., "UA 16+", "A")
  final String? category; // Hollywood, Bollywood, Regional
  final String? trailerUrl; // mtrailerurl
  final String? releaseDate;
  final List<String> genres; // grs
  final List<String> languages; // mfs
  final List<String> formats; // 3D, IMAX, ATMOS, etc.
  final List<Experience> experiences;
  final bool isImax;
  final bool isAdult;

  const Movie({
    required this.id,
    required this.name,
    this.posterVertical,
    this.posterHorizontal,
    this.backdropImage,
    this.runtime,
    this.synopsis,
    this.director,
    this.starring,
    this.certificate,
    this.category,
    this.trailerUrl,
    this.releaseDate,
    this.genres = const [],
    this.languages = const [],
    this.formats = const [],
    this.experiences = const [],
    this.isImax = false,
    this.isAdult = false,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Parse genres from 'grs' array or 'othergenres' string
    List<String> genres = [];
    if (json['grs'] != null) {
      genres = (json['grs'] as List<dynamic>).map((e) => e.toString()).toList();
    } else if (json['othergenres'] != null) {
      genres = (json['othergenres'] as String)
          .split(',')
          .map((e) => e.trim())
          .toList();
    }

    // Parse languages from 'mfs' array or 'otherlanguages' string
    List<String> languages = [];
    if (json['mfs'] != null) {
      languages = (json['mfs'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } else if (json['otherlanguages'] != null) {
      languages = (json['otherlanguages'] as String)
          .split(',')
          .map((e) => e.trim())
          .toList();
    }

    // Parse formats from films array
    List<String> formats = [];
    if (json['films'] != null) {
      final films = json['films'] as List<dynamic>;
      for (final film in films) {
        final format = (film as Map<String, dynamic>)['format'] as String?;
        if (format != null && format.isNotEmpty && !formats.contains(format)) {
          formats.add(format);
        }
      }
    }

    // Parse experiences
    List<Experience> experiences = [];
    if (json['experiences'] != null) {
      experiences = (json['experiences'] as List<dynamic>)
          .map((e) => Experience.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Movie(
      id: json['id']?.toString() ?? json['filmCommonCode']?.toString() ?? '',
      name:
          json['n']?.toString() ??
          json['filmCommonName']?.toString() ??
          json['filmName']?.toString() ??
          '',
      posterVertical: json['miv'] as String?,
      posterHorizontal: json['mih'] as String?,
      backdropImage: json['backdropImage'] as String?,
      runtime: json['mlength'] as String?,
      synopsis: json['synopsis'] as String?,
      director: json['director'] as String?,
      starring: json['starring'] as String?,
      certificate: json['ce'] as String?,
      category: json['category'] as String?,
      trailerUrl: json['mtrailerurl'] as String?,
      releaseDate: json['releaseDate'] as String?,
      genres: genres,
      languages: languages,
      formats: formats,
      experiences: experiences,
      isImax: json['imax'] as bool? ?? false,
      isAdult: json['adult'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'n': name,
    'miv': posterVertical,
    'mih': posterHorizontal,
    'backdropImage': backdropImage,
    'mlength': runtime,
    'synopsis': synopsis,
    'director': director,
    'starring': starring,
    'ce': certificate,
    'category': category,
    'mtrailerurl': trailerUrl,
    'releaseDate': releaseDate,
    'grs': genres,
    'mfs': languages,
    'formats': formats,
    'experiences': experiences.map((e) => e.toJson()).toList(),
    'imax': isImax,
    'adult': isAdult,
  };

  /// Get poster URL (prefer vertical, fallback to horizontal)
  String? get posterUrl => posterVertical ?? posterHorizontal;

  /// Get formatted genres string
  String get genresText => genres.join(', ');

  /// Get formatted languages string
  String get languagesText => languages.join(', ');

  /// Get formatted formats string
  String get formatsText => formats.join(', ');

  /// Get starring cast as list
  List<String> get castList =>
      starring?.split(',').map((e) => e.trim()).toList() ?? [];

  /// Get first 3 cast members
  String get shortCast {
    final cast = castList.take(3).join(', ');
    return castList.length > 3 ? '$cast...' : cast;
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movie && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Experience (IMAX, P[XL], BIGPIX, etc.)
class Experience {
  final String key;
  final String name;
  final String? imageUrl;

  const Experience({required this.key, required this.name, this.imageUrl});

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      key: json['expKey'] as String? ?? '',
      name: json['expName'] as String? ?? '',
      imageUrl: json['expUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'expKey': key,
    'expName': name,
    'expUrl': imageUrl,
  };

  @override
  String toString() => name;
}
