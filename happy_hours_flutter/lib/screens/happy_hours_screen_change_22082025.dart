import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/happy_hour_place.dart';
import '../services/happy_hours_api_service.dart';
import '../widgets/business_card.dart';
import '../widgets/business_details_dialog.dart';

class HappyHoursScreen extends StatefulWidget {
  const HappyHoursScreen({super.key});

  @override
  State<HappyHoursScreen> createState() => _HappyHoursScreenState();
}

class _HappyHoursScreenState extends State<HappyHoursScreen> {
  String selectedLocation = '';
  Set<String> bookmarkedPlaces = {};
  bool showMap = false;
  bool isLoading = true;
  String errorMessage = '';

  List<HappyHourPlace> allBusinesses = [];
  final MapController _mapController = MapController();
  final TextEditingController _locationController = TextEditingController();

  final List<String> autosuggestCities = [
    'Bangkok',
    'Mumbai',
    'New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
    'London', 'Paris', 'Berlin', 'Madrid', 'Rome',
    'Dubai', 'Riyadh', 'Doha', 'Abu Dhabi',
    'Delhi', 'Bangalore', 'Chennai', 'Kolkata',
    'Tokyo', 'Osaka', 'Kyoto',
    'Sydney', 'Melbourne', 'Brisbane',
    'Auckland', 'Wellington',
  ];

  final List<String> businessCategories = [
    'ALL',
    'Restaurant',
    'Bar',
    'Cafe',
    'Fast Food',
    'Spa',
    'Massage',
    'Night Club',
  ];

  String selectedCategory = 'ALL';

  @override
  void initState() {
    super.initState();
    _determinePositionAndLoadData();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _determinePositionAndLoadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationAndFetch(autosuggestCities.first);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setLocationAndFetch(autosuggestCities.first);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setLocationAndFetch(autosuggestCities.first);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final cityCoordinates = {
        'Bangkok': LatLng(13.7563, 100.5018),
        'Mumbai': LatLng(19.0760, 72.8777),
        'New York': LatLng(40.7128, -74.0060),
        'Los Angeles': LatLng(34.0522, -118.2437),
        'Chicago': LatLng(41.8781, -87.6298),
        'Houston': LatLng(29.7604, -95.3698),
        'Phoenix': LatLng(33.4484, -112.0740),
        'London': LatLng(51.5074, -0.1278),
        'Paris': LatLng(48.8566, 2.3522),
        'Berlin': LatLng(52.5200, 13.4050),
        'Madrid': LatLng(40.4168, -3.7038),
        'Rome': LatLng(41.9028, 12.4964),
        'Dubai': LatLng(25.2048, 55.2708),
        'Riyadh': LatLng(24.7136, 46.6753),
        'Doha': LatLng(25.2854, 51.5310),
        'Abu Dhabi': LatLng(24.4539, 54.3773),
        'Delhi': LatLng(28.7041, 77.1025),
        'Bangalore': LatLng(12.9716, 77.5946),
        'Chennai': LatLng(13.0827, 80.2707),
        'Kolkata': LatLng(22.5726, 88.3639),
        'Tokyo': LatLng(35.6762, 139.6503),
        'Osaka': LatLng(34.6937, 135.5023),
        'Kyoto': LatLng(35.0116, 135.7681),
        'Sydney': LatLng(-33.8688, 151.2093),
        'Melbourne': LatLng(-37.8136, 144.9631),
        'Brisbane': LatLng(-27.4698, 153.0251),
        'Auckland': LatLng(-36.8485, 174.7633),
        'Wellington': LatLng(-41.2865, 174.7762),
      };

      String nearestCity = autosuggestCities.first;
      double minDistance = double.infinity;
      final userLatLng = LatLng(position.latitude, position.longitude);

      cityCoordinates.forEach((city, latLng) {
        final distance =
            Distance().as(LengthUnit.Kilometer, userLatLng, latLng);
        if (distance < minDistance) {
          minDistance = distance;
          nearestCity = city;
        }
      });

      _setLocationAndFetch(nearestCity);
    } catch (e) {
      _setLocationAndFetch(autosuggestCities.first);
    }
  }

  Future<void> _setLocationAndFetch(String city, [String business = 'ALL']) async {
    print('Starting fetch for city: $city and business: $business');

    setState(() {
      selectedLocation = city;
      _locationController.text = city;
      isLoading = true;
      errorMessage = '';
    });

    try {
      final places = await fetchHappyHours(city: city, business: business);
      print('Fetch successful, received ${places.length} places');
      setState(() {
        allBusinesses = places;
        isLoading = false;
      });

      if (allBusinesses.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(
            LatLng(allBusinesses.first.latitude, allBusinesses.first.longitude),
            12.0,
          );
        });
      }
    } catch (e) {
      print('Fetch failed with error: $e');
      setState(() {
        errorMessage = 'Failed to load data';
        isLoading = false;
      });
    }
  }

  List<Marker> get _markers {
    return allBusinesses.map((business) {
      return Marker(
        point: LatLng(business.latitude, business.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _openBusinessDetails(business),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.place,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _toggleMapView() {
    setState(() {
      showMap = !showMap;
    });
  }

  void _openBusinessDetails(HappyHourPlace business) {
    showDialog(
      context: context,
      builder: (context) => BusinessDetailsDialog(
        business: business,
        onViewOnMap: () {
          Navigator.pop(context);
          setState(() {
            showMap = true;
          });
          _mapController.move(
            LatLng(business.latitude, business.longitude),
            15.0,
          );
        },
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  // 👉 Filter list by category
  final filteredBusinesses = selectedCategory == 'ALL'
      ? allBusinesses
      : allBusinesses
          .where((b) =>
              b.category.toLowerCase() == selectedCategory.toLowerCase())
          .toList();

  return Scaffold(
    backgroundColor: Colors.white,
    resizeToAvoidBottomInset: false,
    appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Happy Hours',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: _toggleMapView,
          icon: Icon(
            showMap ? Icons.list : Icons.map,
            color: Colors.blue,
          ),
          tooltip: showMap ? 'Show List' : 'Show Map',
        ),
      ],
    ),
    body: SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Column(
                  children: [
                    if (!showMap) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Location input
                            TypeAheadField<String>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.location_on,
                                      color: Colors.blue),
                                  hintText: 'Your current location',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              suggestionsCallback: (pattern) {
                                return autosuggestCities.where((city) =>
                                    city.toLowerCase().contains(
                                        pattern.toLowerCase()));
                              },
                              itemBuilder: (context, String suggestion) {
                                return ListTile(
                                  title: Text(suggestion,
                                      style: const TextStyle(
                                          color: Colors.black)),
                                  tileColor: Colors.white,
                                );
                              },
                              onSuggestionSelected: (String suggestion) {
                                _setLocationAndFetch(suggestion);
                              },
                            ),
                            const SizedBox(height: 12),

                            // Business category buttons
                            SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: businessCategories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final category = businessCategories[index];
                                  final isSelected =
                                      selectedCategory == category;

                                  return ChoiceChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() {
                                        selectedCategory = category;
                                      });

                                      // 🔑 Fetch again with city + business category
                                      _setLocationAndFetch(
                                          selectedLocation, category);
                                    },
                                    selectedColor: Colors.blue,
                                    backgroundColor: Colors.grey[200],
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🔹 SEO Heading + Short Description
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Best Happy Hour Deals Near You", // H1
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Discover the best happy hour spots in your city. "
                              "From local bars, Restaurants, Cafes to global chains, find amazing deals on drinks and food happening right now.",
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                    ],
                    Expanded(
                      child: showMap
                          ? FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: allBusinesses.isNotEmpty
                                    ? LatLng(allBusinesses.first.latitude,
                                        allBusinesses.first.longitude)
                                    : LatLng(0, 0),
                                initialZoom: 12.0,
                                minZoom: 3.0,
                                maxZoom: 18.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.happy_hours_app',
                                  maxZoom: 19,
                                ),
                                MarkerLayer(
                                  markers: _markers,
                                ),
                              ],
                            )
                          : allBusinesses.isEmpty
                              // Case 1: No businesses in this city
                              ? Center(
                                  child: Card(
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    margin: const EdgeInsets.all(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.hourglass_empty,
                                              size: 60,
                                              color: Colors.orangeAccent),
                                          const SizedBox(height: 16),
                                          const Text(
                                            "No Happy Hours Data Available",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "for $selectedLocation",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : filteredBusinesses.isEmpty
                                  // Case 2: City has data but not for this category
                                  ? Center(
                                      child: Card(
                                        elevation: 6,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        margin: const EdgeInsets.all(20),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.hourglass_empty,
                                                  size: 60,
                                                  color: Colors.redAccent),
                                              const SizedBox(height: 16),
                                              const Text(
                                                "No Data Available",
                                                style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                                textAlign:
                                                    TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "for $selectedLocation and Business $selectedCategory",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 16,
                                                ),
                                                textAlign:
                                                    TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  // Case 3: Businesses exist
                                  : ListView.builder(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16),
                                      itemCount:
                                          filteredBusinesses.length,
                                      itemBuilder: (context, index) {
                                        final business =
                                            filteredBusinesses[index];
                                        final isBookmarked =
                                            bookmarkedPlaces
                                                .contains(business.id);

                                        return BusinessCard(
                                          business: business,
                                          isBookmarked: isBookmarked,
                                          onTap: () =>
                                              _openBusinessDetails(
                                                  business),
                                          onBookmarkTap: () {
                                            setState(() {
                                              if (isBookmarked) {
                                                bookmarkedPlaces
                                                    .remove(business.id);
                                              } else {
                                                bookmarkedPlaces
                                                    .add(business.id);
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
    ),
  );
}
}
