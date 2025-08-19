import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/business.dart';
import '../services/data_service.dart';
import '../widgets/business_card.dart';
import '../widgets/business_details_dialog.dart';
import '../widgets/location_selector.dart';

class HappyHoursScreen extends StatefulWidget {
  const HappyHoursScreen({super.key});

  @override
  State<HappyHoursScreen> createState() => _HappyHoursScreenState();
}

class _HappyHoursScreenState extends State<HappyHoursScreen> {
  String searchQuery = '';
  String selectedCategory = 'All';
  String selectedLocation = 'New York';
  Set<String> bookmarkedPlaces = {};
  bool showMap = false;

  late final List<String> categories;
  late final List<PopularLocation> popularLocations;
  late final List<Business> allBusinesses;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    categories = DataService.getCategories();
    popularLocations = DataService.getPopularLocations();
    allBusinesses = DataService.getMockBusinesses();
    selectedLocation = popularLocations.first.name;
  }

  List<Business> get filteredBusinesses => DataService.filterBusinesses(
        allBusinesses,
        searchQuery,
        selectedCategory,
      );

  List<Marker> get _markers {
    return allBusinesses.map((business) {
      return Marker(
        point: LatLng(business.location.latitude, business.location.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _openBusinessDetails(business),
          child: Container(
            decoration: BoxDecoration(
              color: business.isActive ? Colors.green : Colors.blue,
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
            child: Icon(
              _getCategoryIcon(business.category),
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Restaurant':
        return Icons.restaurant;
      case 'Bar':
        return Icons.local_bar;
      case 'Cafe':
        return Icons.local_cafe;
      case 'Fast Food':
        return Icons.fastfood;
      case 'Spa':
        return Icons.spa;
      case 'Massage':
        return Icons.healing;
      default:
        return Icons.place;
    }
  }

  void _toggleMapView() {
    setState(() {
      showMap = !showMap;
    });
  }

  void _focusOnBusiness(Business business) {
    _mapController.move(
      LatLng(business.location.latitude, business.location.longitude),
      15.0,
    );
  }

  void _openLocationSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => LocationSelector(
        locations: popularLocations,
        selectedLocation: selectedLocation,
        onLocationSelected: (name) {
          setState(() {
            selectedLocation = name;
          });
          // Move map to selected location
          final location = popularLocations.firstWhere((loc) => loc.name == name);
          _mapController.move(LatLng(location.latitude, location.longitude), 12.0);
        },
      ),
    );
  }

  void _openBusinessDetails(Business business) {
    showDialog(
      context: context,
      builder: (context) => BusinessDetailsDialog(
        business: business,
        onViewOnMap: () {
          Navigator.pop(context);
          setState(() {
            showMap = true;
          });
          _focusOnBusiness(business);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            if (!showMap) ...[
              // Location and Search Section (only show in list view)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _openLocationSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              selectedLocation,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: popularLocations.length + 1,
                        itemBuilder: (context, index) {
                          if (index == popularLocations.length) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: GestureDetector(
                                onTap: _openLocationSelector,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('More Cities'),
                                ),
                              ),
                            );
                          }

                          final location = popularLocations[index];
                          final isSelected = selectedLocation == location.name;

                          return Padding(
                            padding: EdgeInsets.only(right: 8, left: index == 0 ? 0 : 0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedLocation = location.name;
                                });
                                _mapController.move(LatLng(location.latitude, location.longitude), 12.0);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  location.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search businesses...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category Filter
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],

            // Main Content Area (Map or List)
            Expanded(
              child: showMap
                  ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          allBusinesses.first.location.latitude,
                          allBusinesses.first.location.longitude,
                        ),
                        initialZoom: 12.0,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.happy_hours_app',
                          maxZoom: 19,
                        ),
                        MarkerLayer(
                          markers: _markers,
                        ),
                      ],
                    )
                  : filteredBusinesses.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No businesses found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              Text(
                                'Try adjusting your search or filters',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredBusinesses.length,
                          itemBuilder: (context, index) {
                            final business = filteredBusinesses[index];
                            final isBookmarked = bookmarkedPlaces.contains(business.id);

                            return BusinessCard(
                              business: business,
                              isBookmarked: isBookmarked,
                              onTap: () => _openBusinessDetails(business),
                              onBookmarkTap: () {
                                setState(() {
                                  if (isBookmarked) {
                                    bookmarkedPlaces.remove(business.id);
                                  } else {
                                    bookmarkedPlaces.add(business.id);
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