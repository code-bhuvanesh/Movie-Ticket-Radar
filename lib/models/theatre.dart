/// Theatre model representing a PVR cinema location
class Theatre {
  final String theatreId;
  final String name;
  final String? address;
  final String? city;

  const Theatre({
    required this.theatreId,
    required this.name,
    this.address,
    this.city,
  });

  factory Theatre.fromJson(Map<String, dynamic> json) {
    return Theatre(
      theatreId: json['theatreId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['n']?.toString() ?? 'Unknown',
      address: json['address']?.toString() ?? json['a']?.toString(),
      city: json['city']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'theatreId': theatreId,
    'name': name,
    'address': address,
    'city': city,
  };

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
}
