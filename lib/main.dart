import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/happy_hours_screen_change.dart';
import 'screens/landing_page.dart';
import 'screens/business_login.dart';
import 'screens/business_registration.dart';

void main() {
  runApp(const HappyHoursApp());
}

class HappyHoursApp extends StatefulWidget {
  const HappyHoursApp({super.key});

  @override
  State<HappyHoursApp> createState() => _HappyHoursAppState();
}

class _HappyHoursAppState extends State<HappyHoursApp> {
  Widget _defaultHome = const LandingPage();

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("role");

    setState(() {
      if (role == "user") {
        _defaultHome = const HappyHoursScreen(); // your business listing page
      } else if (role == "business") {
        _defaultHome = const BusinessRegistrationPage();
      } else {
        _defaultHome = const LandingPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Hours',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _defaultHome,
      debugShowCheckedModeBanner: false,
      routes: {
        "/userHome": (context) => const HappyHoursScreen(),
        "/businessRegistration": (context) => const BusinessRegistrationPage(), 
        "/businessLogin": (context) => const BusinessLoginPage(), // <-- add this
        "/landing": (context) => const LandingPage(),
      },
    );
  }
}
