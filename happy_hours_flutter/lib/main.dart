import 'package:flutter/material.dart';
import 'screens/happy_hours_screen_change.dart';
import 'screens/landing_page.dart';
import 'screens/business_login.dart';
import 'screens/business_registration.dart';

void main() {
  runApp(const HappyHoursApp());
}

class HappyHoursApp extends StatelessWidget {
  const HappyHoursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Hours',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // ✅ Always start at LandingPage
      home: const LandingPage(),
      debugShowCheckedModeBanner: false,
      routes: {
        "/userHome": (context) => const HappyHoursScreen(),
        "/businessRegistration": (context) =>  const BusinessRegistrationScreen(),
        "/businessLogin": (context) => const BusinessLoginPage(),
        "/landing": (context) => const LandingPage(),
      },
    );
  }
}
