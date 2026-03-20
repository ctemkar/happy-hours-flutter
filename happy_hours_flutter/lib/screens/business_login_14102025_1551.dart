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
              builder: (context) => BusinessPageByExactName(
                businessName: businessName,
                businessEmail: _emailController.text.trim(),
              ),
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
class BusinessPageByExactName extends StatefulWidget {
  final String businessName;
  final String? businessEmail;

  const BusinessPageByExactName({
    super.key,
    required this.businessName,
    this.businessEmail,
  });

  @override
  State<BusinessPageByExactName> createState() => _BusinessPageByExactNameState();
}

class _BusinessPageByExactNameState extends State<BusinessPageByExactName> {
  late Future<String> _htmlFuture;
  final TextEditingController _htmlController = TextEditingController();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _htmlFuture = _loadHtml(_filePathFromExactName(widget.businessName));
  }

  @override
  void dispose() {
    _htmlController.dispose();
    super.dispose();
  }

  String _filePathFromExactName(String exactName) {
    final path = 'output_html/$exactName.html';
    debugPrint('Business page asset path => $path');
    return path;
  }

  Future<String> _loadHtml(String path) async {
    try {
      final html = await rootBundle.loadString(path);
      _htmlController.text = html; // seed editor
      return html;
    } catch (e) {
      debugPrint('Failed to load asset: $path, error: $e');
      final fallback = """
        <html>
          <body style="font-family:sans-serif; padding:16px;">
            <h2 style='color:red; text-align:center;'>No page found for "${widget.businessName}".</h2>
            <p style='text-align:center;'>Tried: $path</p>
            <pre>$e</pre>
          </body>
        </html>
      """;
      _htmlController.text = fallback;
      return fallback;
    }
  }

  // Edit icon -> toggle editor
  void _onEdit() {
    setState(() => _isEditMode = true);
  }

  // Save icon -> send updated HTML to backend
  Future<void> _onSave() async {
    final payload = {
      "business_name": widget.businessName,
      if (widget.businessEmail != null) "email": widget.businessEmail,
      // Send full edited HTML. Backend can store it or parse and update fields.
      "content_html": _htmlController.text,
    };

    try {
      final resp = await http.post(
        Uri.parse("https://app.lovehappyhours.com/happy-hours-api/update_business"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );
      debugPrint('Update response: ${resp.statusCode} ${resp.body}');

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body["success"] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Saved successfully")),
          );
          // Immediately reflect edits in view mode without re-reading the asset
          setState(() {
            _isEditMode = false;
            _htmlFuture = Future.value(_htmlController.text);
          });
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Save failed (${resp.statusCode})."),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Delete icon -> confirm and call backend
  Future<void> _onDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Business"),
        content: const Text("Are you sure you want to delete this business? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final resp = await http.post(
        Uri.parse("https://app.lovehappyhours.com/happy-hours-api/delete_business"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "business_name": widget.businessName,
          if (widget.businessEmail != null) "email": widget.businessEmail,
        }),
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body["success"] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Business deleted successfully")),
          );
          Navigator.of(context).popUntil((r) => r.isFirst);
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed (${resp.statusCode})."), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String path = _filePathFromExactName(widget.businessName);
    debugPrint('kIsWeb = $kIsWeb');

    return FutureBuilder<String>(
      future: _htmlFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final html = snapshot.data ?? "";

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.businessName,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF6a0dad),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (!_isEditMode)
                IconButton(
                  tooltip: "Edit",
                  icon: const Icon(Icons.edit),
                  onPressed: loading ? null : _onEdit,
                ),
              IconButton(
                tooltip: "Delete",
                icon: const Icon(Icons.delete),
                onPressed: loading ? null : _onDelete,
              ),
              IconButton(
                tooltip: "Save",
                icon: const Icon(Icons.save),
                onPressed: (_isEditMode && !loading) ? _onSave : null,
              ),
            ],
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : _isEditMode
                  // Simple HTML editor. Replace with field-level UI if you prefer.
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          "Editing ${widget.businessName} page HTML",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6a0dad),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _htmlController,
                          maxLines: 28,
                          decoration: InputDecoration(
                            labelText: "HTML Content",
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF6a0dad), width: 2),
                            ),
                          ),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Note: Currently editing the entire HTML. You can later replace this editor with structured input fields mapped to your DB columns (happy_hours_global_test).",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    )
                  : kIsWeb
                      ? SingleChildScrollView(
                          child: HtmlWidget(
                            html,
                            // If your HTML references relative CSS/JS,
                            // prefer inlining CSS or using absolute URLs.
                          ),
                        )
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