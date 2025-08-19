import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/happy_hour_place.dart';

Future<List<HappyHourPlace>> fetchHappyHours(String city) async {
  final url = Uri.parse('https://customercallsapp.com/prod/customercallsapp/happy_hours_global_api.php?city=$city');
  final response = await http.get(url);

  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    // Parse JSON only once
    final List<dynamic> jsonList = json.decode(response.body);
    print('Parsed ${jsonList.length} items');

    // Optional: Print first item for inspection
    if (jsonList.isNotEmpty) {
      print('First item: ${jsonList[0]}');
    }

    // Convert to HappyHourPlace objects
    final places = jsonList.map((json) => HappyHourPlace.fromJson(json)).toList();

    // Optional: Print first object details
    if (places.isNotEmpty) {
      print('First place name: ${places[0].name}');
      print('First place hours: ${places[0].openHours}');
    }

    return places;
  } else {
    // Handle error properly
    throw Exception('Failed to load happy hours data. Status: ${response.statusCode}');
  }
}