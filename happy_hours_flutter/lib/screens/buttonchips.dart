import 'package:flutter/material.dart';

void main() {
  runApp(const HappyHoursApp());
}

class HappyHoursApp extends StatelessWidget {
  const HappyHoursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Hours',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const BusinessChipsScreen(),
    );
  }
}

class BusinessChipsScreen extends StatelessWidget {
  const BusinessChipsScreen({super.key});

  final List<String> businesses = const [
    "The Rooftop Bar",
    "Bangkok Lounge",
    "Happy Hours Café",
    "Skyline Drinks",
    "Poolside Bar"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Happy Hour Businesses"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: businesses.map((business) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Bright white background
                foregroundColor: Colors.deepPurple, // Text color
                elevation: 6, // Attractive shadow
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Colors.deepPurple, width: 1.5),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Selected: $business")),
                );
              },
              child: Text(
                business,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
