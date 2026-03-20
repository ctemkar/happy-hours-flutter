import 'package:flutter/material.dart';
import 'business_registration.dart';

class BusinessLoginPage extends StatelessWidget {
  const BusinessLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Login" , style: TextStyle(
      color: Colors.white, // ✅ White text
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),),
        backgroundColor: const Color(0xFF6a0dad),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                // TODO: implement login check
                Navigator.pushReplacementNamed(context, "/businessRegistration");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6a0dad),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
              ),
              child: const Text("Login", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BusinessRegistrationPage()),
                );
              },
              child: const Text("Not registered? Register Now"),
            ),
          ],
        ),
      ),
    );
  }
}
