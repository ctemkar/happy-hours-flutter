class HappyHourPlace {
  final String id;
  final String name;
  final String address;
  final String googleMarker;
  final String imageLink;
  final String openHours;
  final String happyHourStart;
  final String happyHourEnd;
  final String telephone;
  final double latitude;
  final double longitude;
  final String category; // ✅ Added category field

  HappyHourPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.googleMarker,
    required this.imageLink,
    required this.openHours,
    required this.happyHourStart,
    required this.happyHourEnd,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.category, // ✅ Added in constructor
  });

  factory HappyHourPlace.fromJson(Map<String, dynamic> json) {
    return HappyHourPlace(
      id: json['happy_hours_id'] ?? '',
      name: json['Name'] ?? '',
      address: json['Address'] ?? '',
      googleMarker: json['Google_Marker'] ?? '',
      imageLink: json['image_link'] ?? '',
      openHours: json['Open_hours'] ?? '',
      happyHourStart: json['Happy_hour_start'] ?? '',
      happyHourEnd: json['Happy_hour_end'] ?? '',
      telephone: json['Telephone'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      category: json['Business_category'] ?? 'Uncategorized', // ✅ Fallback value
    );
  }
}
