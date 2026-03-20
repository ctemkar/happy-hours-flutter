class Location {
  final String address;
  final double latitude;
  final double longitude;

  Location({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class Discount {
  final String title;
  final int percentage;
  final String description;
  final String validFrom;
  final String validTo;
  final bool isActive;

  Discount({
    required this.title,
    required this.percentage,
    required this.description,
    required this.validFrom,
    required this.validTo,
    required this.isActive,
  });
}

class HappyHourPlace {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final Location location;
  final double rating;
  final String category;
  final bool isActive;
  final bool isVerified;
  final Discount? currentDiscount;

  HappyHourPlace({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.rating,
    required this.category,
    required this.isActive,
    required this.isVerified,
    this.currentDiscount,
  });
}

class PopularLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  PopularLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}