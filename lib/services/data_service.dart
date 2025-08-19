import 'package:flutter/material.dart';
import '../models/business.dart';

class DataService {
  static bool isDiscountActive(String startTime, String endTime) {
    final now = TimeOfDay.now();
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static List<String> getCategories() {
    return [
      'All',
      'Restaurant',
      'Bar',
      'Cafe',
      'Fast Food',
      'Spa',
      'Massage'
    ];
  }

  static List<PopularLocation> getPopularLocations() {
    return [
      PopularLocation(id: '1', name: 'New York', latitude: 40.7128, longitude: -74.0060),
      PopularLocation(id: '2', name: 'Los Angeles', latitude: 34.0522, longitude: -118.2437),
      PopularLocation(id: '3', name: 'London', latitude: 51.5074, longitude: -0.1278),
      PopularLocation(id: '4', name: 'Paris', latitude: 48.8566, longitude: 2.3522),
      PopularLocation(id: '5', name: 'Tokyo', latitude: 35.6762, longitude: 139.6503),
    ];
  }

  static List<Business> getMockBusinesses() {
    return [
      Business(
        id: '1',
        name: 'The Rooftop Bar',
        description: 'Stunning city views with craft cocktails and live music',
        imageUrl: 'https://images.pexels.com/photos/1267320/pexels-photo-1267320.jpeg',
        location: Location(address: '123 Sky Avenue, New York', latitude: 40.7589, longitude: -73.9851),
        rating: 4.8,
        category: 'Bar',
        isActive: isDiscountActive('18:00', '22:00'),
        isVerified: true,
        currentDiscount: Discount(
          title: 'Happy Hour Special',
          percentage: 30,
          description: 'All cocktails and appetizers',
          validFrom: '18:00',
          validTo: '22:00',
          isActive: isDiscountActive('18:00', '22:00'),
        ),
      ),
      Business(
        id: '2',
        name: 'Bella Vista Restaurant',
        description: 'Authentic Italian cuisine with romantic ambiance',
        imageUrl: 'https://images.pexels.com/photos/262978/pexels-photo-262978.jpeg',
        location: Location(address: '456 Pasta Street, New York', latitude: 40.7505, longitude: -73.9934),
        rating: 4.6,
        category: 'Restaurant',
        isActive: isDiscountActive('17:30', '19:30'),
        isVerified: true,
        currentDiscount: Discount(
          title: 'Early Bird Special',
          percentage: 25,
          description: 'Three-course dinner menu',
          validFrom: '17:30',
          validTo: '19:30',
          isActive: isDiscountActive('17:30', '19:30'),
        ),
      ),
      Business(
        id: '3',
        name: 'Coffee Corner',
        description: 'Artisan coffee and fresh pastries in cozy atmosphere',
        imageUrl: 'https://images.pexels.com/photos/302899/pexels-photo-302899.jpeg',
        location: Location(address: '789 Bean Boulevard, New York', latitude: 40.7614, longitude: -73.9776),
        rating: 4.4,
        category: 'Cafe',
        isActive: isDiscountActive('15:00', '17:00'),
        isVerified: false,
        currentDiscount: Discount(
          title: 'Afternoon Delight',
          percentage: 20,
          description: 'Coffee and pastry combo',
          validFrom: '15:00',
          validTo: '17:00',
          isActive: isDiscountActive('15:00', '17:00'),
        ),
      ),
      Business(
        id: '4',
        name: 'Sunset Grill',
        description: 'Waterfront dining with fresh seafood and steaks',
        imageUrl: 'https://images.pexels.com/photos/1581384/pexels-photo-1581384.jpeg',
        location: Location(address: '321 Harbor View, New York', latitude: 40.7282, longitude: -74.0776),
        rating: 4.7,
        category: 'Restaurant',
        isActive: isDiscountActive('16:00', '18:00'),
        isVerified: true,
        currentDiscount: Discount(
          title: 'Sunset Special',
          percentage: 35,
          description: 'Seafood platters and drinks',
          validFrom: '16:00',
          validTo: '18:00',
          isActive: isDiscountActive('16:00', '18:00'),
        ),
      ),
      Business(
        id: '5',
        name: 'Craft Beer House',
        description: 'Local craft beers with gourmet pub food',
        imageUrl: 'https://images.pexels.com/photos/1552630/pexels-photo-1552630.jpeg',
        location: Location(address: '654 Brewery Lane, New York', latitude: 40.7831, longitude: -73.9712),
        rating: 4.5,
        category: 'Bar',
        isActive: isDiscountActive('19:00', '21:00'),
        isVerified: true,
        currentDiscount: Discount(
          title: 'Craft Hour',
          percentage: 40,
          description: 'All craft beers and wings',
          validFrom: '19:00',
          validTo: '21:00',
          isActive: isDiscountActive('19:00', '21:00'),
        ),
      ),
      Business(
        id: '6',
        name: 'Serenity Spa & Wellness',
        description: 'Full-service spa offering massages, facials, and wellness treatments',
        imageUrl: 'https://images.pexels.com/photos/3757942/pexels-photo-3757942.jpeg',
        location: Location(address: '100 Wellness Way, New York', latitude: 40.7549, longitude: -73.9840),
        rating: 4.9,
        category: 'Spa',
        isActive: isDiscountActive('14:00', '16:00'),
        isVerified: true,
        currentDiscount: Discount(
          title: 'Afternoon Relaxation',
          percentage: 30,
          description: 'All spa services and treatments',
          validFrom: '14:00',
          validTo: '16:00',
          isActive: isDiscountActive('14:00', '16:00'),
        ),
      ),
      Business(
        id: '7',
        name: 'Tranquil Touch Massage',
        description: 'Therapeutic massage therapy for stress relief and relaxation',
        imageUrl: 'https://images.pexels.com/photos/3757952/pexels-photo-3757952.jpeg',
        location: Location(address: '250 Calm Street, New York', latitude: 40.7686, longitude: -73.9918),
        rating: 4.7,
        category: 'Massage',
        isActive: isDiscountActive('11:00', '13:00'),
        isVerified: true,
        currentDiscount: Discount(
          title: 'Midday Massage',
          percentage: 25,
          description: 'Swedish and deep tissue massage',
          validFrom: '11:00',
          validTo: '13:00',
          isActive: isDiscountActive('11:00', '13:00'),
        ),
      ),
      Business(
        id: '8',
        name: 'Urban Oasis Day Spa',
        description: 'Luxury day spa with premium treatments and amenities',
        imageUrl: 'https://images.pexels.com/photos/3757946/pexels-photo-3757946.jpeg',
        location: Location(address: '500 Luxury Lane, New York', latitude: 40.7505, longitude: -73.9758),
        rating: 4.8,
        category: 'Spa',
        isActive: isDiscountActive('10:00', '12:00'),
        isVerified: true,
        currentDiscount: Discount(
          title: 'Morning Bliss',
          percentage: 35,
          description: 'Facial and body treatments',
          validFrom: '10:00',
          validTo: '12:00',
          isActive: isDiscountActive('10:00', '12:00'),
        ),
      ),
      Business(
        id: '9',
        name: 'Healing Hands Therapy',
        description: 'Professional massage therapy for pain relief and wellness',
        imageUrl: 'https://images.pexels.com/photos/3757943/pexels-photo-3757943.jpeg',
        location: Location(address: '75 Therapy Avenue, New York', latitude: 40.7420, longitude: -74.0020),
        rating: 4.6,
        category: 'Massage',
        isActive: isDiscountActive('13:00', '15:00'),
        isVerified: false,
        currentDiscount: Discount(
          title: 'Healing Hour',
          percentage: 20,
          description: 'Therapeutic massage sessions',
          validFrom: '13:00',
          validTo: '15:00',
          isActive: isDiscountActive('13:00', '15:00'),
        ),
      ),
      Business(
        id: '10',
        name: 'Zen Garden Wellness Center',
        description: 'Holistic wellness center with meditation and spa services',
        imageUrl: 'https://images.pexels.com/photos/3757941/pexels-photo-3757941.jpeg',
        location: Location(address: '888 Zen Path, New York', latitude: 40.7749, longitude: -73.9442),
        rating: 4.9,
        category: 'Spa',
        isActive: isDiscountActive('16:30', '18:30'),
        isVerified: true,
        currentDiscount: Discount(
          title: 'Evening Zen',
          percentage: 40,
          description: 'Meditation and wellness packages',
          validFrom: '16:30',
          validTo: '18:30',
          isActive: isDiscountActive('16:30', '18:30'),
        ),
      ),
    ];
  }

  static List<Business> filterBusinesses(
    List<Business> businesses,
    String searchQuery,
    String selectedCategory,
  ) {
    var filteredBusinesses = businesses.where((business) {
      final matchesSearch = business.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          business.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          business.location.address.toLowerCase().contains(searchQuery.toLowerCase());
      
      final matchesCategory = selectedCategory == 'All' || business.category == selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();

    // Smart sorting algorithm
    filteredBusinesses.sort((a, b) {
      // 1. Currently active discounts first
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;
      
      // 2. Businesses with any scheduled discounts
      if (a.currentDiscount != null && b.currentDiscount == null) return -1;
      if (a.currentDiscount == null && b.currentDiscount != null) return 1;
      
      // 3. Verified businesses
      if (a.isVerified && !b.isVerified) return -1;
      if (!a.isVerified && b.isVerified) return 1;
      
      // 4. Highest rated businesses
      return b.rating.compareTo(a.rating);
    });

    return filteredBusinesses;
  }
}