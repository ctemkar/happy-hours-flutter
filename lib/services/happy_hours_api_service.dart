import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/happy_hour_place.dart';

/*Future<List<HappyHourPlace>> fetchHappyHours({
  required String city,   // always required
  String? business,       // optional
}) async {
  // Start with city
  String urlString = 'https://customercallsapp.com/prod/customercallsapp/happy_hours_global_api.php?city=$city';

  // Append business if provided (and not "ALL")
  //if (business != null && business.isNotEmpty && business != 'ALL') {
  //  urlString += '&business=$business';
  //}

  if (business != null && business.isNotEmpty && business != 'ALL') {
    urlString += '&business=${Uri.encodeComponent(business)}';
  }

  final url = Uri.parse(urlString);
  final response = await http.get(url);

  print('API URL: $urlString');
  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    print('Parsed ${jsonList.length} items');

    if (jsonList.isNotEmpty) {
      print('First item: ${jsonList[0]}');
    }

    final places = jsonList.map((json) => HappyHourPlace.fromJson(json)).toList();

    if (places.isNotEmpty) {
      print('First place name: ${places[0].name}');
      print('First place hours: ${places[0].openHours}');
    }

    return places;
  } else {
    throw Exception('Failed to load happy hours data. Status: ${response.statusCode}');
  }
}*/

Future<List<HappyHourPlace>> fetchHappyHours({
  required String city,   // always required
  String business = "ALL", // defaults to ALL
}) async {
  // Always start with city
  String urlString =
      'https://customercallsapp.com/prod/customercallsapp/happy_hours_global_api_new.php?city=${Uri.encodeComponent(city)}';

  // If business is anything other than ALL, append it
  if (business.isNotEmpty && business.toUpperCase() != 'ALL') {
    urlString += '&business=${Uri.encodeComponent(business)}';
  }

  final url = Uri.parse(urlString);
  final response = await http.get(url);

  print('=== Fetch Happy Hours API Call ===');
  print('API URL: $urlString');
  print('Response status: ${response.statusCode}');

  if (response.statusCode == 200) {
    try {
      final List<dynamic> jsonList = json.decode(response.body);

      print('Parsed ${jsonList.length} items');

      if (jsonList.isNotEmpty) {
        print('First item: ${jsonList[0]}');
      }

      final places = jsonList.map((json) => HappyHourPlace.fromJson(json)).toList();

      if (places.isNotEmpty) {
        print('First place name: ${places[0].name}');
        print('First place hours: ${places[0].openHours}');
      }

      return places;
    } catch (e) {
      print('Error decoding JSON: $e');
      throw Exception('Invalid response format from API');
    }
  } else {
    throw Exception('Failed to load happy hours data. Status: ${response.statusCode}');
  }
}
