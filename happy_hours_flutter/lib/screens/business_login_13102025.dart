import 'dart:convert';
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
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Make sure this path matches your Flask route
    final url = Uri.parse(
      "https://app.lovehappyhours.com/happy-hours-api/business_login",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final businessName = data["business_name"]?.toString();
          if (businessName == null || businessName.trim().isEmpty) {
            setState(() {
              _errorMessage = "Login succeeded but no business_name returned.";
            });
            return;
          }

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BusinessPageByExactName(businessName: businessName),
            ),
          );
        } else {
          setState(() {
            _errorMessage = data["message"] ?? "Login failed. Please try again.";
          });
        }
      } else {
        // Show server error message if present
        String message;
        try {
          final data = jsonDecode(response.body);
          message = data["message"] ?? "Login failed (${response.statusCode}).";
        } catch (_) {
          message = "Login failed (${response.statusCode}).";
        }
        setState(() => _errorMessage = message);
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error connecting to server: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BusinessRegistrationPage(),
                  ),
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

// ================== Business Page (by exact name) ==================
class BusinessPageByExactName extends StatelessWidget {
  final String businessName;
  const BusinessPageByExactName({super.key, required this.businessName});

  Future<String> _loadHtml(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      // Fallback HTML if file not found
      debugPrint('Failed to load asset: $path, error: $e');
      return """
        <html>
          <body style="font-family:sans-serif; padding:16px;">
            <h2 style='color:red; text-align:center;'>No page found for "$businessName".</h2>
            <p style='text-align:center;'>Tried: $path</p>
            <pre>$e</pre>
          </body>
        </html>
      """;
    }
  }

  // IMPORTANT: Using exact DB name as the filename. Adjust if your real files have a prefix.
  String _filePathFromExactName(String exactName) {
    // If your files are named like "business <Name>.html", change to:
    // return 'assets/output_html/business $exactName.html';
    //return 'output_html/$exactName.html';
    final path = 'output_html/$exactName.html';
    debugPrint('Business page asset path => $path');
     return path;

  }

  @override
  Widget build(BuildContext context) {
    final String path = _filePathFromExactName(businessName);

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    return FutureBuilder<String>(
      future: _loadHtml(path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        controller.loadHtmlString(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              businessName,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF6a0dad),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: WebViewWidget(controller: controller),
        );
      },
    );
  }
}