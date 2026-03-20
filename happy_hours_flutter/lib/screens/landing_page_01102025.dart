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
      Navigator.pushReplacementNamed(context, "/businessLogin");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFfdfbff), Color(0xFFf4eaff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                const Text(
                  "Welcome to Happy Hours",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6a0dad),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Select your portal below. If you’re a user, explore amazing happy hour deals near you.\n"
                  "If you’re a business owner, register your business and showcase your offers.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Grid-like layout
                Wrap(
                  spacing: 40,
                  runSpacing: 40,
                  alignment: WrapAlignment.center,
                  children: [
                    // User Card
                    _buildCard(
                      context,
                      title: "User",
                      description:
                          "Discover exciting Happy Hour deals near you. Explore listings from bars, restaurants, and cafes.",
                      buttonText: "Explore Listings",
                      role: "user",
                    ),

                    // Business Owner Card
                    _buildCard(
                      context,
                      title: "Business Owner",
                      description:
                          "Register your business and showcase your happy hour offers to thousands of potential customers.",
                      buttonText: "Business Login",
                      role: "business",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required String role,
  }) {
    return InkWell(
      onTap: () => _setRole(context, role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6a0dad),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => _setRole(context, role),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6a0dad),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
