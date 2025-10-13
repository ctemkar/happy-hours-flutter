import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

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
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse(
      "https://app.lovehappyhours.com/happy-hours-api/business_login",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      debugPrint('Login response: ${response.statusCode} ${response.body}');

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
            _errorMessage =
                data["message"] ?? "Login failed. Please try again.";
          });
        }
      } else {
        String message;
        try {
          final data = jsonDecode(response.body);
          message =
              data["message"] ?? "Login failed (${response.statusCode}).";
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                prefixIcon: const Icon(Icons.email, color: Color(0xFF6a0dad)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF6a0dad), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF6a0dad)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF6a0dad),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF6a0dad), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 25),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
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
      final html = await rootBundle.loadString(path);
      return html;
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

  // Since your DB Name equals the exact file name (without .html),
  // we simply map to output_html/<Name>.html
  String _filePathFromExactName(String exactName) {
    final path = 'output_html/$exactName.html';
    debugPrint('Business page asset path => $path');
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final String path = _filePathFromExactName(businessName);
    // Log which platform branch is taken
    debugPrint('kIsWeb = $kIsWeb');

    return FutureBuilder<String>(
      future: _loadHtml(path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final html = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              businessName,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF6a0dad),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: kIsWeb
              // On Web: render HTML directly to avoid WebView null issues
              ? SingleChildScrollView(
                  child: HtmlWidget(
                    html,
                    // If your HTML references relative CSS/JS,
                    // prefer inlining CSS or using absolute URLs.
                  ),
                )
              // On Android/iOS: use WebView
              : _MobileWebView(html: html),
        );
      },
    );
  }
}

class _MobileWebView extends StatelessWidget {
  final String html;
  const _MobileWebView({required this.html});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(html);

    return WebViewWidget(controller: controller);
  }
}