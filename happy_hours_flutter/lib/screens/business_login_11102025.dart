import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'business_registration.dart';

class BusinessLoginPage extends StatefulWidget {
  const BusinessLoginPage({super.key});

  @override
  State<BusinessLoginPage> createState() => _BusinessLoginPageState();
}

class _BusinessLoginPageState extends State<BusinessLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 👉 Use correct URL depending on environment
    //final url = Uri.parse("http://127.0.0.1:5000/business_login");
    // For Android emulator, use: http://10.0.2.2:5000/business_login
    // For real device: http://YOUR_PC_LOCAL_IP:5000/business_login

    final url = Uri.parse("https://app.lovehappyhours.com/happy-hours-api/business_login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"]) {
          final businessId = data["business_id"];

          // Navigate to BusinessPage with ID
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BusinessPage(businessId: businessId.toString()),
            ),
          );
        } else {
          setState(() {
            _errorMessage = data["message"];
          });
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data["message"] ?? "Login failed. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error connecting to server: $e";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6a0dad),
        title: const Text(
          "Business Login",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 25),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6a0dad),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 25),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                // Navigate to registration if needed
                // Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessRegistrationPage()));
                Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BusinessRegistrationPage()),
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

// ================== BusinessPage ==================
class BusinessPage extends StatelessWidget {
  final String businessId;
  const BusinessPage({super.key, required this.businessId});

  Future<String> _loadHtml(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return "<html><body><h2 style='color:red;text-align:center;'>No page found for this business.</h2></body></html>";
    }
  }

  @override
  Widget build(BuildContext context) {
    final String filePath = 'assets/output_html/business_$businessId.html';

    return FutureBuilder<String>(
      future: _loadHtml(filePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              "Business Page",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF6a0dad),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: WebViewWidget(
            controller: WebViewController()
              ..loadHtmlString(snapshot.data!), // Load HTML from assets
          ),
        );
      },
    );
  }
}
