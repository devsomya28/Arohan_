class Location {
  final double lat;
  final double long;
  final int? floor;

  Location({
    required this.lat,
    required this.long,
    this.floor,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'long': long,
      'floor': floor,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat'].toDouble(),
      long: json['long'].toDouble(),
      floor: json['floor'],
    );
  }
}
