/// City model representing a PVR city location
class City {
  final String id;
  final String name;

  const City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
