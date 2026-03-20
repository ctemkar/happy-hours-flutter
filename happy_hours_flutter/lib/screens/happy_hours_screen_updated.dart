import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/happy_hour_place.dart';
import '../services/happy_hours_api_service.dart';
import '../widgets/business_card.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

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

  // Map controller fixes
  bool _mapIsReady = false;
  LatLng? _pendingCenter;
  double _pendingZoom = 12.0;

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

  // Safe filename generation
  String businessNameToFilename(String name) {
    var s = name.trim();
    s = s.replaceAll(RegExp(r'[^\w\s-]'), ''); // remove non-word chars
    s = s.replaceAll(RegExp(r'[-\s]+'), '_');  // spaces/hyphens -> underscore
    s = s.replaceAll(RegExp(r'_+'), '_');      // collapse multiple underscores
    if (s.length > 120) s = s.substring(0, 120);
    if (s.isEmpty) s = 'place';
    return '$s.html';
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
        final center = LatLng(allBusinesses.first.latitude, allBusinesses.first.longitude);
        _pendingCenter = center;
        _pendingZoom = 12.0;

        if (showMap && _mapIsReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(center, _pendingZoom);
          });
        }
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
    
    if (showMap && _mapIsReady && _pendingCenter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_pendingCenter!, _pendingZoom);
      });
    }
  }

  void _openBusinessDetails(HappyHourPlace business) async {
    final filename = businessNameToFilename(business.name);
    debugPrint("Opening details for: ${business.name} -> $filename");

    if (kIsWeb) {
      // On Web: open the HTML file from assets directly in the same tab
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BusinessHtmlPage(
            filename: filename, 
            title: business.name,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
      return;
    }

    // On Mobile: open inside the app using InAppWebView
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            BusinessHtmlPage(filename: filename, title: business.name),
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
                              // Location input with dropdown
                              DropdownButtonFormField<String>(
                                value: selectedLocation.isNotEmpty ? selectedLocation : null,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                                  hintText: 'Your current location',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                                items: autosuggestCities
                                    .map((city) => DropdownMenuItem<String>(
                                          value: city,
                                          child: Text(city),
                                        ))
                                    .toList(),
                                onChanged: (city) {
                                  if (city == null) return;
                                  // Keep controller text in sync for any other usages
                                  _locationController.text = city;
                                  setState(() {
                                    selectedLocation = city;
                                  });
                                  _setLocationAndFetch(city, selectedCategory);
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
                            ? Stack(
                                children: [
                                  // 🔹 MAP VIEW
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: allBusinesses.isNotEmpty
                                          ? LatLng(allBusinesses.first.latitude,
                                              allBusinesses.first.longitude)
                                          : LatLng(0, 0),
                                      initialZoom: 12.0,
                                      minZoom: 3.0,
                                      maxZoom: 18.0,
                                      onMapReady: () {
                                        setState(() {
                                          _mapIsReady = true;
                                          if (_pendingCenter != null) {
                                            _mapController.move(_pendingCenter!, _pendingZoom);
                                          }
                                        });
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.example.happy_hours_app',
                                        maxZoom: 19,
                                      ),
                                      MarkerLayer(markers: _markers),
                                    ],
                                  ),

                                  // 🔹 ZOOM CONTROLS
                                  Positioned(
                                    top: 20,
                                    right: 10,
                                    child: Column(
                                      children: [
                                        FloatingActionButton(
                                          heroTag: "zoomIn",
                                          mini: true,
                                          backgroundColor: Colors.white,
                                          onPressed: () {
                                            if (!_mapIsReady) return;
                                            _mapController.move(
                                              _mapController.camera.center,
                                              _mapController.camera.zoom + 1,
                                            );
                                          },
                                          child: const Icon(Icons.add, color: Colors.black),
                                        ),
                                        const SizedBox(height: 8),
                                        FloatingActionButton(
                                          heroTag: "zoomOut",
                                          mini: true,
                                          backgroundColor: Colors.white,
                                          onPressed: () {
                                            if (!_mapIsReady) return;
                                            _mapController.move(
                                              _mapController.camera.center,
                                              _mapController.camera.zoom - 1,
                                            );
                                          },
                                          child: const Icon(Icons.remove, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 🔹 GOOGLE MAPS + DIRECTIONS BUTTONS
                                  if (allBusinesses.isNotEmpty)
                                    Positioned(
                                      bottom: 20,
                                      left: 20,
                                      right: 20,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // View on Google Maps
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 14),
                                              elevation: 6,
                                            ),
                                            onPressed: () async {
                                              final lat = allBusinesses.first.latitude;
                                              final lng = allBusinesses.first.longitude;
                                              final url = Uri.parse(
                                                  "https://www.google.com/maps/search/?api=1&query=$lat,$lng");

                                              if (!await launchUrl(
                                                url,
                                                mode: LaunchMode.platformDefault,
                                                webOnlyWindowName:
                                                    '_blank',
                                              )) {
                                                throw Exception("Could not launch $url");
                                              }
                                            },
                                            icon: const Icon(Icons.map, color: Colors.white),
                                            label: const Text("Google Maps",
                                                style: TextStyle(color: Colors.white)),
                                          ),

                                          // Directions Button
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 14),
                                              elevation: 6,
                                            ),
                                            onPressed: () async {
                                              final lat = allBusinesses.first.latitude;
                                              final lng = allBusinesses.first.longitude;
                                              final url = Uri.parse(
                                                  "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");

                                              if (!await launchUrl(
                                                url,
                                                mode: LaunchMode.platformDefault,
                                                webOnlyWindowName:
                                                    '_blank',
                                              )) {
                                                throw Exception("Could not launch $url");
                                              }
                                            },
                                            icon: const Icon(Icons.directions, color: Colors.white),
                                            label: const Text("Directions",
                                                style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              )
                            : allBusinesses.isEmpty
                                // Case 1: No businesses in this city
                                ? Center(
                                    child: Card(
                                      elevation: 6,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      margin: const EdgeInsets.all(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.hourglass_empty,
                                                size: 60, color: Colors.orangeAccent),
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
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          margin: const EdgeInsets.all(20),
                                          child: Padding(
                                            padding: const EdgeInsets.all(24.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.hourglass_empty,
                                                    size: 60, color: Colors.redAccent),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  "No Data Available",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "for $selectedLocation and Business $selectedCategory",
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
                                    // Case 3: Businesses exist
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        itemCount: filteredBusinesses.length,
                                        itemBuilder: (context, index) {
                                          final business = filteredBusinesses[index];
                                          final isBookmarked =
                                              bookmarkedPlaces.contains(business.id);

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

// ------------------------- Business HTML Page Widget (Updated) -------------------------
class BusinessHtmlPage extends StatefulWidget {
  final String filename;
  final String title;
  final VoidCallback? onBack;

  const BusinessHtmlPage({
    required this.filename,
    required this.title,
    this.onBack,
    super.key,
  });

  @override
  State<BusinessHtmlPage> createState() => _BusinessHtmlPageState();
}

class _BusinessHtmlPageState extends State<BusinessHtmlPage> {
  String? htmlData;
  bool loading = true;
  String? error;

  // Comprehensive inline CSS (update as needed). This will be injected into every HTML file.
  static const String inlineCSS = '''
  /* Import Inter font */
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700;800&display=swap');

  :root{
    --bg: #ffffff;
    --text: #111827;
    --muted: #6b7280;
    --brand-1: #0ea5a4;
    --brand-2: #0369a1;
    --card: #f8fafc;
    --radius: 12px;
  }

  html,body{
    margin:0;
    padding:0;
    font-family: 'Inter', system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial;
    background:var(--bg);
    color:var(--text);
    -webkit-font-smoothing:antialiased;
    -moz-osx-font-smoothing:grayscale;
  }

  .container{
    max-width:980px;
    margin:0 auto;
    padding:0 16px;
  }

  header{ padding:18px 0 }
  .brand{ font-weight:700; font-size:18px; color:var(--brand-2) }
  .nav-links a{ color:var(--muted); text-decoration:none; margin-left:8px }

  .hero{ padding:18px 0 }
  .hero-card{
    display:flex;
    gap:16px;
    background:var(--card);
    border-radius:var(--radius);
    padding:16px;
    align-items:center;
  }
  .hero-img{ width:220px; height:140px; object-fit:cover; border-radius:8px; }

  .grid{ display:grid; grid-template-columns: 1fr 320px; gap:16px; align-items:start }
  .card{ background:var(--card); padding:14px; border-radius:10px; box-shadow: 0 1px 2px rgba(0,0,0,0.03) }
  .muted{ color:var(--muted); font-size:14px }

  .chip{ background:#e6f3f3; color:var(--brand-2); padding:6px 8px; border-radius:8px; margin-right:6px; font-size:13px }

  h1.title{ margin:0; font-size:20px; font-weight:800 }
  h3{ margin-top:0; font-size:16px }

  .hours-list{ list-style:none; padding:0; margin:0 }
  .hours-row{ display:flex; justify-content:space-between; padding:6px 0; border-bottom:1px solid rgba(0,0,0,0.04) }
  .time{ color:var(--brand-2); font-weight:600 }

  .map{ width:100%; height:260px; border:0; border-radius:8px; }

  .badge{ background:#fff4cc; color:#92400e; padding:6px 8px; border-radius:8px; font-size:13px }

  footer{ padding:18px 0; color:var(--muted); text-align:center; font-size:13px }

  /* Responsive */
  @media (max-width:800px){
    .grid{ grid-template-columns: 1fr; }
    .hero-card{ flex-direction:column; }
    .hero-img{ width:100%; height:200px }
  }
  ''';

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  // Remove <link rel="stylesheet"...> and inject inline CSS. Returns processed HTML.
  String _injectCSSIntoHtml(String html) {
    try {
      // Remove <link rel="stylesheet"...> tags (many variants)
      final cleaned = html.replaceAll(RegExp(r'<link[^>]+rel=["\']stylesheet["\'][^>]*>', caseSensitive: false), '');

      // Inject <style>...</style> into head if present, else create head
      final styleTag = '<style>${inlineCSS}</style>';

      if (cleaned.contains(RegExp(r'</head>', caseSensitive: false))) {
        return cleaned.replaceFirstMapped(RegExp(r'</head>', caseSensitive: false),
            (m) => '$styleTag${m.group(0)}');
      } else if (cleaned.contains(RegExp(r'<head[^>]*>', caseSensitive: false))) {
        // head exists but no closing head - fallback
        return cleaned.replaceFirstMapped(RegExp(r'<head[^>]*>', caseSensitive: false),
            (m) => '${m.group(0)}$styleTag');
      } else if (cleaned.contains(RegExp(r'<html[^>]*>', caseSensitive: false))) {
        // Put a head after html tag
        return cleaned.replaceFirstMapped(RegExp(r'<html[^>]*>', caseSensitive: false),
            (m) => '${m.group(0)}<head>$styleTag</head>');
      } else {
        // No html/head at all - just prepend style
        return '$styleTag$cleaned';
      }
    } catch (e) {
      // If anything fails, return original html (safer)
      return html;
    }
  }

  Future<void> _loadHtml() async {
    setState(() {
      loading = true;
      error = null;
      htmlData = null;
    });

    try {
      String raw;
      if (kIsWeb) {
        // On Web, try to fetch the file via relative path (served from assets)
        final uri = Uri.parse('assets/output_html/${widget.filename}');
        final response = await http.get(uri);
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        raw = response.body;
      } else {
        // On mobile, load from bundled assets
        raw = await rootBundle.loadString('output_html/${widget.filename}');
      }

      final injected = _injectCSSIntoHtml(raw);

      setState(() {
        htmlData = injected;
        loading = false;
      });
    } catch (e, st) {
      setState(() {
        error = 'Could not load file: ${widget.filename}\n$e';
        loading = false;
      });
      debugPrint('BusinessHtmlPage load error: $e\n$st');
    }
  }

  // Helper to open external URLs (tel:, maps, mailto:, http(s))
  Future<void> _openExternally(String urlStr) async {
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        throw 'Could not launch $urlStr';
      }
    } catch (e) {
      debugPrint('Failed to open external url $urlStr : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: widget.onBack != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                )
              : null,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: widget.onBack != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                )
              : null,
        ),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );
    }

    // htmlData is available
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: kIsWeb
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: HtmlWidget(
                  htmlData ?? '<p>No Data</p>',
                  // Open links externally where appropriate
                  onTapUrl: (url) async {
                    if (url == null) return true;
                    await _openExternally(url);
                    return true;
                  },
                  // allow simple inline styling/imageloads etc.
                ),
              ),
            )
          : InAppWebView(
              initialData: InAppWebViewInitialData(
                data: htmlData ?? '<p>No Data</p>',
                // baseUrl is about:blank; if you have local resources you may need to set a file baseUrl
                baseUrl: Uri.parse('about:blank').toString(),
                encoding: 'utf-8',
              ),
              initialOptions: InAppWebViewGroupOptions(
                android: AndroidInAppWebViewOptions(
                  useHybridComposition: true,
                  // enable shouldOverrideUrlLoading to intercept links
                  useShouldInterceptRequest: true,
                ),
                ios: IOSInAppWebViewOptions(
                  allowsInlineMediaPlayback: true,
                ),
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                ),
              ),
              onWebViewCreated: (controller) async {
                // nothing extra needed on create
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                if (uri == null) return NavigationActionPolicy.CANCEL;

                // If user taps tel:, mailto:, intent: or external maps or different host, open externally
                final scheme = uri.scheme?.toLowerCase();
                final host = uri.host?.toLowerCase() ?? '';

                if (scheme == 'tel' || scheme == 'mailto' || scheme == 'sms') {
                  await _openExternally(uri.toString());
                  return NavigationActionPolicy.CANCEL;
                }

                // Common mapping / external links to open externally:
                if (uri.toString().contains('google.com/maps') ||
                    uri.toString().contains('maps.google') ||
                    host.contains('maps') ||
                    uri.toString().startsWith('https://www.google.com/maps')) {
                  await _openExternally(uri.toString());
                  return NavigationActionPolicy.CANCEL;
                }

                // If the link points to an external site (not useful inside the static page),
                // open externally. You can customize this check.
                if (scheme == 'http' || scheme == 'https') {
                  // If you want to allow same-page anchors or same-origin navigation, add checks here.
                  // For static pages we usually allow it inside the WebView. We'll allow it.
                  return NavigationActionPolicy.ALLOW;
                }

                // Default: allow
                return NavigationActionPolicy.ALLOW;
              },
              onLoadError: (controller, url, code, message) {
                debugPrint('WebView load error $code $message');
              },
              onLoadHttpError: (controller, url, statusCode, description) {
                debugPrint('HTTP error $statusCode $description');
              },
            ),
    );
  }
}