import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessOwnerPage extends StatelessWidget {
  const BusinessOwnerPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("role"); // reset role
    Navigator.pushReplacementNamed(context, "/landing");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Business Portal"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Business Owner!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 20),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.purple[50],
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.store, color: Colors.purple),
                title: const Text(
                  "Manage Your Business",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text("Edit details, offers, and happy hours"),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.purple),
                onTap: () {
                  // TODO: Navigate to business details / registration page
                },
              ),
            ),

            const SizedBox(height: 16),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.purple[50],
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.web, color: Colors.purple),
                title: const Text(
                  "View Your Business Page",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                subtitle: const Text("Preview your static web page"),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.purple),
                onTap: () {
                  // TODO: Navigate to static business web page
                },
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "Switch Role / Logout",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
