import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/happy_hour_place.dart';

Future<List<HappyHourPlace>> fetchHappyHours({
  required String city,
  String business = "ALL",
}) async {
  //const String BASE_URL = 'https://app.lovehappyhours.com/happy-hours-api'; // Flask root route
  const String BASE_URL = 'https://app.lovehappyhours.com/happy-hours-api/happy_hours_business'; // Flask root route

  // Add this line here:
  print('USING_FLASK_BASE_URL: $BASE_URL');

  String urlString = '$BASE_URL?city=${Uri.encodeComponent(city)}';
  if (business.isNotEmpty && business.toUpperCase() != 'ALL') {
    urlString += '&business=${Uri.encodeComponent(business)}';
  }

  final response = await http.get(Uri.parse(urlString));

  print('=== Fetch Happy Hours (Python) ===');
  print('API URL: $urlString');
  print('Response status: ${response.statusCode}');

  if (response.statusCode == 200) {
    try {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((j) => HappyHourPlace.fromJson(j)).toList();
    } catch (e) {
      print('Error decoding JSON: $e');
      throw Exception('Invalid response format from API');
    }
  } else {
    throw Exception('Failed to load happy hours data. Status: ${response.statusCode}');
  }
}
