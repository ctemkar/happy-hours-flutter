import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Future<void> _setRole(BuildContext context, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("role", role);

    if (role == "user") {
      Navigator.pushReplacementNamed(context, "/userHome");
    } else {
      Navigator.pushReplacementNamed(context, "/businessOwner");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome to Happy Hours",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // User Card
              GestureDetector(
                onTap: () => _setRole(context, "user"),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.purple[100],
                  elevation: 6,
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: Center(
                      child: Text(
                        "I am a User",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple[900],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Business Owner Card
              GestureDetector(
                onTap: () => _setRole(context, "business"),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.purple[200],
                  elevation: 6,
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: Center(
                      child: Text(
                        "I am a Business Owner",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple[900],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
