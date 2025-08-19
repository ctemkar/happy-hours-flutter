import 'package:flutter/material.dart';
import 'screens/happy_hours_screen_change.dart';

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
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2196F3),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HappyHoursScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}