import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'business_registration.dart';

/// Normalize business name for filename lookup
/// "Yummy Fast Food" → "Yummy-Fast-Food"
String normalizeBusinessName(String name) {
  return name.trim().replaceAll(RegExp(r'\s+'), '-');
}

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

  @override
  void initState() {
    super.initState();
    _htmlFuture = _loadHtml();
  }

  // Try server first, fallback to local asset
  Future<String> _loadHtml() async {
    // 1. Try fetching from server
    try {
      final response = await http.post(
        Uri.parse("https://app.lovehappyhours.com/happy-hours-api/get_business"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"business_name": widget.businessName}),
      );

      debugPrint('Server fetch response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["content_html"] != null) {
          debugPrint('✅ Loaded HTML from server for ${widget.businessName}');
          return data["content_html"] as String;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Server fetch failed: $e, falling back to asset');
    }

    // 2. Fallback to local asset with normalized filename
    final normalizedName = normalizeBusinessName(widget.businessName);
    final path = 'output_html/$normalizedName.html';
    try {
      final html = await rootBundle.loadString(path);
      debugPrint('✅ Loaded HTML from asset: $path');
      return html;
    } catch (e) {
      debugPrint('❌ Asset load failed: $path, error: $e');
      return """
        <html>
          <body style="font-family:sans-serif; padding:16px;">
            <h2 style='color:red; text-align:center;'>No page found for "${widget.businessName}".</h2>
            <p style='text-align:center;'>Tried server and asset: $path</p>
            <pre>$e</pre>
          </body>
        </html>
      """;
    }
  }

  void _onEdit() async {
    final html = await _htmlFuture;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessStructuredEditPage(
          businessName: widget.businessName,
          businessEmail: widget.businessEmail,
          initialHtml: html,
          onSaved: (newHtml) {
            // 1) Instant optimistic UI update with the HTML we just saved
            setState(() {
              _htmlFuture = Future.value(newHtml);
            });
            // 2) Background truth refresh from server to ensure consistency
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  _htmlFuture = _loadHtml();
                });
              }
            });
          },
        ),
      ),
    );
  }

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
            ],
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : kIsWeb
                  ? SingleChildScrollView(child: HtmlWidget(html))
                  : _MobileWebView(html: html),
        );
      },
    );
  }
}

// =============== Structured Edit Page (client-side parsing) ===============
class BusinessStructuredEditPage extends StatefulWidget {
  final String businessName;
  final String? businessEmail;
  final String initialHtml;
  final void Function(String newHtml) onSaved;

  const BusinessStructuredEditPage({
    super.key,
    required this.businessName,
    this.businessEmail,
    required this.initialHtml,
    required this.onSaved,
  });

  @override
  State<BusinessStructuredEditPage> createState() => _BusinessStructuredEditPageState();
}

class _BusinessStructuredEditPageState extends State<BusinessStructuredEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _parsing = true;
  bool _saving = false;

  // Controllers (plain text)
  final nameCtrl = TextEditingController();
  final taglineCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final shortAddressCtrl = TextEditingController();
  final openHoursLineCtrl = TextEditingController();
  final happyHoursLineCtrl = TextEditingController();
  final aboutCtrl = TextEditingController();
  final openingHoursCtrl = TextEditingController();
  final happyHoursCtrl = TextEditingController();
  final currentOffersCtrl = TextEditingController();
  final locationAddressCtrl = TextEditingController();
  final contactPhoneCtrl = TextEditingController();
  final contactEmailCtrl = TextEditingController();
  final contactAddressCtrl = TextEditingController();
  final dressCodeCtrl = TextEditingController();
  final facilitiesCtrl = TextEditingController();
  final goodToKnowCtrl = TextEditingController();
  final paymentMethodsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _parseHtmlToFields(widget.initialHtml);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    taglineCtrl.dispose();
    cityCtrl.dispose();
    shortAddressCtrl.dispose();
    openHoursLineCtrl.dispose();
    happyHoursLineCtrl.dispose();
    aboutCtrl.dispose();
    openingHoursCtrl.dispose();
    happyHoursCtrl.dispose();
    currentOffersCtrl.dispose();
    locationAddressCtrl.dispose();
    contactPhoneCtrl.dispose();
    contactEmailCtrl.dispose();
    contactAddressCtrl.dispose();
    dressCodeCtrl.dispose();
    facilitiesCtrl.dispose();
    goodToKnowCtrl.dispose();
    paymentMethodsCtrl.dispose();
    super.dispose();
  }

  // Strip tags helper
  String _stripTags(String s) =>
      s.replaceAll(RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true), '')
       .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
       .replaceAll(RegExp(r'<[^>]*>'), '\n')
       .replaceAll('&nbsp;', ' ')
       .replaceAll('\r', '')
       .split('\n')
       .map((e) => e.trim())
       .where((e) => e.isNotEmpty)
       .join('\n');

  String? _firstMatch(String html, RegExp re) => re.firstMatch(html)?.group(1);

  // Parse your provided HTML layout
  void _parseHtmlToFields(String html) {
    try {
      // Title h1
      nameCtrl.text = _stripTags(_firstMatch(html, RegExp(r'<h1[^>]*class="[^"]*title[^"]*"[^>]*>(.*?)</h1>', caseSensitive: false, dotAll: true)) ?? widget.businessName);

      // Tagline p.sub under hero
      taglineCtrl.text = _stripTags(_firstMatch(html, RegExp(r'<p[^>]*class="[^"]*sub[^"]*"[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true)) ?? '');

      // Chips: city • short address, open hours, happy hours
      final chipsBlock = _firstMatch(html, RegExp(r'<div[^>]*style="[^"]*margin-top:12px[^"]*"[^>]*>(.*?)</div>', caseSensitive: false, dotAll: true)) ?? '';
      // Extract individual chip spans (inner text)
      final chipMatches = RegExp(r'<span[^>]*class="[^"]*chip[^"]*"[^>]*>(.*?)</span>', caseSensitive: false, dotAll: true)
          .allMatches(chipsBlock)
          .map((m) => _stripTags(m.group(1) ?? ''))
          .toList();
      // Heuristic based on your HTML order
      if (chipMatches.isNotEmpty) {
        // 0: "Bangkok • Soi Sukhumvit 15"
        final parts = chipMatches[0].split('•').map((e) => e.trim()).toList();
        if (parts.isNotEmpty) cityCtrl.text = parts[0];
        if (parts.length > 1) shortAddressCtrl.text = parts[1];
      }
      if (chipMatches.length > 1) {
        openHoursLineCtrl.text = chipMatches[1]; // "Open daily 9:00:00–23:30:00"
      }
      if (chipMatches.length > 2) {
        happyHoursLineCtrl.text = chipMatches[2]; // "Happy Hour 15:00:00–19:00:00"
      }

      // About block: <section id="about"> ... <div>About text</div>
      aboutCtrl.text = _stripTags(_firstMatch(html, RegExp(r'<section[^>]*id="about"[^>]*>.*?<div[^>]*class="card"[^>]*>.*?<h3>About<\/h3>\s*<div[^>]*>(.*?)<\/div>', caseSensitive: false, dotAll: true)) ?? '');

      // Opening Hours list: collect each li day + time into lines "Monday 9:00 – 23:30"
      final hoursBlock = _firstMatch(html, RegExp(r'<aside[^>]*id="hours"[^>]*>.*?<ul[^>]*class="[^"]*hours-list[^"]*"[^>]*>(.*?)</ul>', caseSensitive: false, dotAll: true)) ?? '';
      final hoursRows = RegExp(r'<li[^>]*class="[^"]*hours-row[^"]*"[^>]*>.*?<span[^>]*class="[^"]*day[^"]*"[^>]*>(.*?)</span>.*?<span[^>]*class="[^"]*time[^"]*"[^>]*>(.*?)</span>.*?</li>',
          caseSensitive: false, dotAll: true).allMatches(hoursBlock);
      final openingLines = <String>[];
      for (final m in hoursRows) {
        final day = _stripTags(m.group(1) ?? '');
        final time = _stripTags(m.group(2) ?? '');
        if (day.isNotEmpty || time.isNotEmpty) openingLines.add('$day $time'.trim());
      }
      openingHoursCtrl.text = openingLines.join('\n');

      // Happy Hour section: one muted line + one list row with time
      final happyBlock = _firstMatch(html, RegExp(r'<section[^>]*id="happy"[^>]*>.*?<article[^>]*class="card"[^>]*>.*?<h3>Happy Hour</h3>(.*?)</article>', caseSensitive: false, dotAll: true)) ?? '';
      // muted line
      final muted = _stripTags(_firstMatch(happyBlock, RegExp(r'<p[^>]*class="[^"]*muted[^"]*"[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true)) ?? '');
      // time line inside <li class="hours-row"><span>Daily</span><span class="time">15:00..</span>
      String dailyTime = '';
      final happyRow = RegExp(r'<li[^>]*class="[^"]*hours-row[^"]*"[^>]*>.*?<span[^>]*>(.*?)</span>.*?<span[^>]*class="[^"]*time[^"]*"[^>]*>(.*?)</span>.*?</li>',
          caseSensitive: false, dotAll: true).firstMatch(happyBlock);
      if (happyRow != null) {
        final day = _stripTags(happyRow.group(1) ?? '');
        final time = _stripTags(happyRow.group(2) ?? '');
        dailyTime = [day, time].where((e) => e.isNotEmpty).join(' ');
      }
      happyHoursCtrl.text = [muted, dailyTime].where((e) => e.trim().isNotEmpty).join('\n');

      // Current Offers section: list items; combine into lines
      final offersBlock = _firstMatch(html, RegExp(r'<aside[^>]*id="offers"[^>]*>.*?<ul[^>]*class="[^"]*list[^"]*"[^>]*>(.*?)</ul>', caseSensitive: false, dotAll: true)) ?? '';
      final offerLis = RegExp(r'<li[^>]*>(.*?)</li>', caseSensitive: false, dotAll: true).allMatches(offersBlock).map((m) => _stripTags(m.group(1) ?? '')).toList();
      currentOffersCtrl.text = offerLis.join('\n');

      // Location address: <section id="map"> ... <p>ADDRESS</p>
      locationAddressCtrl.text = _stripTags(_firstMatch(html, RegExp(r'<section[^>]*id="map"[^>]*>.*?<div[^>]*class="card"[^>]*>.*?<h3>Location<\/h3>\s*<p[^>]*>(.*?)<\/p>', caseSensitive: false, dotAll: true)) ?? '');

      // Contact: phone (tel link), address text
      contactPhoneCtrl.text = _stripTags(_firstMatch(html, RegExp(r'<aside[^>]*id="contact"[^>]*>.*?Phone:\s*<\/div>\s*<div[^>]*>.*?>(\+?[0-9()\-\s]+)<\/a>', caseSensitive: false, dotAll: true)) ?? '');
      contactAddressCtrl.text = _stripTags(_firstMatch(html, RegExp(r'<aside[^>]*id="contact"[^>]*>.*?Address:\s*<\/div>\s*<div[^>]*>(.*?)<\/div>', caseSensitive: false, dotAll: true)) ?? '');
      // No email in your HTML; keep empty
      contactEmailCtrl.text = '';

      // Good to Know items
      dressCodeCtrl.text = _stripTags(_firstMatch(html, RegExp(r'Dress Code:\s*<\/span>\s*<span[^>]*class="[^"]*gtk-value[^"]*"[^>]*>(.*?)<\/span>', caseSensitive: false, dotAll: true)) ?? '');
      facilitiesCtrl.text = _stripTags(_firstMatch(html, RegExp(r'Facilities:\s*<\/span>\s*<span[^>]*class="[^"]*gtk-value[^"]*"[^>]*>(.*?)<\/span>', caseSensitive: false, dotAll: true)) ?? '');
      goodToKnowCtrl.text = _stripTags(_firstMatch(html, RegExp(r'Good to Know:\s*<\/span>\s*<span[^>]*class="[^"]*gtk-value[^"]*"[^>]*>(.*?)<\/span>', caseSensitive: false, dotAll: true)) ?? '');
      paymentMethodsCtrl.text = _stripTags(_firstMatch(html, RegExp(r'Payment Methods:\s*<\/span>\s*<span[^>]*class="[^"]*gtk-value[^"]*"[^>]*>(.*?)<\/span>', caseSensitive: false, dotAll: true)) ?? '');
    } catch (e) {
      debugPrint('Parsing error: $e');
    } finally {
      setState(() {
        _parsing = false;
      });
    }
  }

  // Build HTML back to your exact structure with edited values
  String _buildHtmlFromFields() {
    // Helpers
    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    List<String> _lines(String text) =>
        text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final title = esc(nameCtrl.text);
    final tagline = esc(taglineCtrl.text);
    final city = esc(cityCtrl.text);
    final shortAddr = esc(shortAddressCtrl.text);
    final openInline = esc(openHoursLineCtrl.text);
    final happyInline = esc(happyHoursLineCtrl.text);
    final about = esc(aboutCtrl.text);

    final openingLines = _lines(openingHoursCtrl.text).map(esc).toList();
    final happyLines = _lines(happyHoursCtrl.text).map(esc).toList();
    final offers = _lines(currentOffersCtrl.text).map(esc).toList();

    final locationAddr = esc(locationAddressCtrl.text);
    final contactPhone = esc(contactPhoneCtrl.text);
    final contactEmail = esc(contactEmailCtrl.text);
    final contactAddress = esc(contactAddressCtrl.text);

    final dressCode = esc(dressCodeCtrl.text);
    final facilities = esc(facilitiesCtrl.text);
    final goodToKnow = esc(goodToKnowCtrl.text);
    final paymentMethods = esc(paymentMethodsCtrl.text);

    // Opening hours UL
    final openingHoursUl = openingLines.isEmpty
        ? ''
        : openingLines.map((l) {
            // Expect format "Monday 9:00 – 23:30" (any text before first number treated as day)
            final parts = RegExp(r'^([^\d]+)\s*(.*)$').firstMatch(l);
            final day = (parts?.group(1) ?? '').trim();
            final time = (parts?.group(2) ?? '').trim();
            return '<li class="hours-row"><span class="day">$day</span><span class="time">$time</span></li>';
          }).join('\n');

    // Happy hour: first line muted note, second line time row
    String happyMuted = '';
    String happyRow = '';
    if (happyLines.isNotEmpty) {
      happyMuted = '<p class="meta muted">${happyLines.first}</p>';
      if (happyLines.length > 1) {
        final second = happyLines[1];
        final parts = RegExp(r'^([^\d]+)\s*(.*)$').firstMatch(second);
        final day = (parts?.group(1) ?? '').trim();
        final time = (parts?.group(2) ?? '').trim();
        happyRow =
            '<ul class="list"><li class="hours-row"><span>$day</span><span class="time" style="color:var(--brand-2);font-weight:700">$time</span></li></ul>';
      }
    }

    // Current offers
    final offersUl = offers.isEmpty
        ? ''
        : '<ul class="list">\n${offers.map((o) => '<li><span>$o</span></li>').join('\n')}\n</ul>';

    // Contact phone link
    final phoneHref = contactPhone.isNotEmpty ? 'tel:${contactPhone.replaceAll(' ', '')}' : '#';

    // Good to know list
    String gtkItem(String label, String value) =>
        '<li class="gtk-item"><span class="gtk-label">$label: </span><span class="gtk-value">$value</span></li>';

    // Final HTML (keeps your CSS and structure)
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$title | Bangkok</title>
  <meta name="description" content="$title in Bangkok — hours, happy hours, offers, photos, map, and contact details." />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root{--card:#f9fafb;--muted:#6b7280;--brand-2:#12a56a;--shadow:0 2px 8px rgba(0,0,0,0.08);--radius:12px}
    *{box-sizing:border-box}
    html,body{height:100%}
    body{margin:0;font-family:Inter,system-ui,Arial;color:#1f2937;background:#fff;line-height:1.6;padding-top:68px}
    a{color:#2563eb;text-decoration:none}
    .container{width:min(1120px,92vw);margin:0 auto;padding:0 12px}
    header{position:fixed;top:0;left:0;right:0;z-index:999;background:#fff;border-bottom:1px solid #e5e7eb;box-shadow:0 2px 4px rgba(0,0,0,0.04)}
    .nav{display:flex;align-items:center;justify-content:space-between;padding:12px 0}
    .brand{font-weight:800}
    .nav-links a{color:var(--muted);margin:0 6px}
    .nav-links a:hover{text-decoration:underline}
    .hero{padding:48px 0}
    .hero-card{background:var(--card);border-radius:20px;padding:22px;display:grid;grid-template-columns:1.6fr 1fr;gap:18px;box-shadow:var(--shadow)}
    .title{font-size:clamp(28px,4vw,40px);margin:6px 0}
    .sub{color:var(--muted)}
    .chip{background:#eef2ff;border-radius:10px;padding:8px 10px;color:#4338ca;font-size:12px;margin-right:8px;display:inline-block}
    .hero-img{width:100%;height:100%;object-fit:cover;border-radius:12px}
    .card{background:var(--card);border-radius:var(--radius);padding:16px;box-shadow:var(--shadow);margin-bottom:14px}
    .grid{display:grid;grid-template-columns:1.1fr 1fr;gap:18px}
    .list{list-style:none;padding:0;margin:10px 0 0}
    .muted{color:var(--muted)}
    .badge{font-size:12px;padding:6px 8px;border-radius:8px;background:#dcfce7;color:#166534;border:1px solid #bbf7d0}
    .hours-list{list-style:none;padding:0;margin:10px 0 0}
    .hours-row{display:flex;align-items:center;gap:8px;padding:12px 0;border-bottom:1px dashed #e5e7eb}
    .hours-row:last-child{border-bottom:none}
    .day{font-weight:500}
    .time{margin-left:auto;text-align:right;color:#1f2937}
    .gtk-list{list-style:none;padding:0;margin:10px 0 0}
    .gtk-item{display:flex;align-items:center;gap:8px;padding:12px 0;border-bottom:1px dashed #e5e7eb}
    .gtk-item:last-child{border-bottom:none}
    .gtk-label{font-weight:600;white-space:nowrap;color:#1f2937}
    .gtk-value{color:#1f2937}
    .map{width:100%;height:280px;border:0;border-radius:12px}
    footer{color:var(--muted);padding:18px 0}
    @media (max-width:900px){
      .hero-card{grid-template-columns:1fr}
      .grid{grid-template-columns:1fr}
      body{padding-top:76px}
    }
  </style>
</head>
<body>
  <header>
    <div class="container nav">
      <div class="brand">Bangkok Happy Hours</div>
      <nav class="nav-links">
        <a href="#about">About</a> •
        <a href="#hours">Hours</a> •
        <a href="#happy">Happy Hour</a> •
        <a href="#offers">Offers</a>
      </nav>
    </div>
  </header>

  <main>
    <section class="hero">
      <div class="container hero-card">
        <div>
          <h1 class="title">$title</h1>
          ${tagline.isNotEmpty ? '<p class="sub">$tagline</p>' : ''}
          <div style="margin-top:12px">
            ${city.isNotEmpty || shortAddr.isNotEmpty ? '<span class="chip">${[city, shortAddr].where((e)=>e.isNotEmpty).join(' • ')}</span>' : ''}
            ${openInline.isNotEmpty ? '<span class="chip">$openInline</span>' : ''}
            ${happyInline.isNotEmpty ? '<span class="chip">$happyInline</span>' : ''}
          </div>
        </div>
        <div class="hero-media">
          <img src="https://customercallsapp.com/prod/customercallsapp/business_images/Rainforest-rooftop-bar.jpg" alt="$title photo" class="hero-img" />
        </div>
      </div>
    </section>

    <section id="about" class="container grid">
      <article class="card">
        <h3>About</h3>
        <div>$about</div>
      </article>

      <aside id="hours" class="card">
        <h3>Opening Hours</h3>
        <ul class="hours-list">
          $openingHoursUl
        </ul>
        <p class="meta muted">Note: Hours may vary on holidays and during special events.</p>
      </aside>
    </section>

    <section id="happy" class="container grid">
      <article class="card">
        <h3>Happy Hour</h3>
        $happyMuted
        ${happyRow.isNotEmpty ? happyRow : ''}
      </article>

      <aside id="offers" class="card">
        <h3>Current Offers</h3>
        $offersUl
      </aside>
    </section>

    <section id="map" class="container" style="margin-top:14px">
      <div class="card">
        <h3>Location</h3>
        ${locationAddr.isNotEmpty ? '<p>$locationAddr</p>' : ''}
        <iframe class="map" loading="lazy" src="https://www.google.com/maps?q=${Uri.encodeComponent(locationAddr.isNotEmpty ? locationAddr : 'Bangkok')}&output=embed" allowfullscreen></iframe>
        <div style="position:absolute;bottom:0;left:0;width:100%;height:30px;background:transparent;z-index:2;"></div>
      </div>

      <aside id="contact" class="card" style="margin-top:14px">
        <h3>Contact</h3>
        <div style="margin-bottom:8px">
          <div class="muted">Phone: </div>
          <div>${contactPhone.isNotEmpty ? '<a href="$phoneHref">$contactPhone</a>' : '-'}</div>
        </div>
        ${contactEmail.isNotEmpty ? '<div class="muted">Email: </div><div><a href="mailto:$contactEmail">$contactEmail</a></div>' : ''}
        <div class="muted" style="margin-top:8px">Address: </div>
        <div>${contactAddress.isNotEmpty ? contactAddress : (locationAddr.isNotEmpty ? locationAddr : '-')}</div>
      </aside>
    </section>

    <section class="container" style="margin-top:14px">
      <div class="card">
        <h3>Good to Know</h3>
        <ul class="gtk-list">
          ${dressCode.isNotEmpty ? '${gtkItem('Dress Code', dressCode)}' : ''}
          ${facilities.isNotEmpty ? '${gtkItem('Facilities', facilities)}' : ''}
          ${goodToKnow.isNotEmpty ? '${gtkItem('Good to Know', goodToKnow)}' : ''}
          ${paymentMethods.isNotEmpty ? '${gtkItem('Payment Methods', paymentMethods)}' : ''}
        </ul>
      </div>
    </section>
  </main>

  <footer class="container">
    <div>© 2025 Bangkok Happy Hours • This is a static informational page.</div>
  </footer>
</body>
</html>
''';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final newHtml = _buildHtmlFromFields();
    final payload = {
      "business_name": widget.businessName,
      if (widget.businessEmail != null && widget.businessEmail!.isNotEmpty)
        "email": widget.businessEmail,
      "content_html": newHtml,
    };

    try {
      final resp = await http.post(
        Uri.parse("https://app.lovehappyhours.com/happy-hours-api/update_business"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      debugPrint('Update response: ${resp.statusCode} ${resp.body}');

      final body = (resp.body.isNotEmpty) ? jsonDecode(resp.body) : null;
      final msg = (body is Map && body["message"] is String) ? body["message"] as String : null;

      if (resp.statusCode == 200 && (body is Map && body["success"] == true)) {
          if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg ?? "Saved successfully")),
            );
            // Pass the just-saved HTML up so parent can show it instantly
            widget.onSaved(newHtml);
            Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? "Save failed (${resp.statusCode})."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF6a0dad), width: 2),
        ),
      );

  Widget _sectionTitle(String txt) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          txt,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF6a0dad)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6a0dad),
        title: Text("Edit ${widget.businessName}", style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: "Save",
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _parsing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle("Header"),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _dec("Business Name (bold)"),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: taglineCtrl, decoration: _dec("One-liner (below name)")),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: cityCtrl, decoration: _dec("City"))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: shortAddressCtrl, decoration: _dec("Short Address"))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: openHoursLineCtrl, decoration: _dec("Open Hours (inline chip)"))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: happyHoursLineCtrl, decoration: _dec("Happy Hours (inline chip)"))),
                    ],
                  ),

                  _sectionTitle("About"),
                  TextFormField(controller: aboutCtrl, decoration: _dec("About (one-liner)")),

                  _sectionTitle("Opening Hours"),
                  TextFormField(controller: openingHoursCtrl, maxLines: 7, decoration: _dec("Opening Hours (one day per line e.g. Monday 9:00 – 23:30)")),

                  _sectionTitle("Happy Hour"),
                  TextFormField(controller: happyHoursCtrl, maxLines: 4, decoration: _dec("Line 1: note (e.g., Except Fri-Sat), Line 2: e.g. Daily 15:00 – 19:00")),

                  _sectionTitle("Current Offers"),
                  TextFormField(controller: currentOffersCtrl, maxLines: 4, decoration: _dec("One offer per line")),

                  _sectionTitle("Location"),
                  TextFormField(controller: locationAddressCtrl, maxLines: 2, decoration: _dec("Address (used above map + for map URL)")),

                  _sectionTitle("Contact"),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: contactPhoneCtrl, decoration: _dec("Phone"))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: contactEmailCtrl, decoration: _dec("Email (optional)"))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: contactAddressCtrl, decoration: _dec("Contact Address (optional, defaults to Location)")),

                  _sectionTitle("Good To Know"),
                  TextFormField(controller: dressCodeCtrl, decoration: _dec("Dress Code")),
                  const SizedBox(height: 12),
                  TextFormField(controller: facilitiesCtrl, decoration: _dec("Facilities")),
                  const SizedBox(height: 12),
                  TextFormField(controller: goodToKnowCtrl, decoration: _dec("Good To Know")),
                  const SizedBox(height: 12),
                  TextFormField(controller: paymentMethodsCtrl, decoration: _dec("Payment Methods")),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text("Save Changes"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6a0dad),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
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