/// Movie model representing a now-showing movie
class Movie {
  final String id;
  final String name;
  final String? posterUrl;
  final String? language;
  final String? genre;

  const Movie({
    required this.id,
    required this.name,
    this.posterUrl,
    this.language,
    this.genre,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id']?.toString() ?? '',
      name: json['n']?.toString() ?? json['name']?.toString() ?? 'Unknown',
      posterUrl: json['ih']?.toString() ?? json['posterUrl']?.toString(),
      language: json['l']?.toString() ?? json['language']?.toString(),
      genre: json['g']?.toString() ?? json['genre']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'n': name,
    'ih': posterUrl,
    'l': language,
    'g': genre,
  };

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movie && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
