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
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // For now, bypass API and directly navigate to test.html
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const BusinessPageByExactName(
          businessName: "test",
          userEmail: "", // Pass email if needed later
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
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
class BusinessPageByExactName extends StatefulWidget {
  final String businessName;
  final String userEmail;
  
  const BusinessPageByExactName({
    super.key, 
    required this.businessName,
    this.userEmail = "",
  });

  @override
  State<BusinessPageByExactName> createState() => _BusinessPageByExactNameState();
}

class _BusinessPageByExactNameState extends State<BusinessPageByExactName> {
  String? _htmlContent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHtmlContent();
  }

  Future<void> _loadHtmlContent() async {
    try {
      // First try to fetch from API with timeout
      final response = await http.get(
        Uri.parse('https://app.lovehappyhours.com/happy-hours-api/get_page/${widget.businessName}'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['html'] != null) {
          setState(() {
            _htmlContent = data['html'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch from API: $e');
    }

    // Fallback to local asset
    try {
      final html = await rootBundle.loadString('output_html/${widget.businessName}.html');
      setState(() {
        _htmlContent = html;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load asset: $e');
      setState(() {
        _htmlContent = _getFallbackHtml();
        _isLoading = false;
      });
    }
  }

  String _getFallbackHtml() {
    return """
      <html>
        <body style="font-family:sans-serif; padding:16px;">
          <h2 style='color:red; text-align:center;'>No page found for "${widget.businessName}".</h2>
          <p style='text-align:center;'>Please contact support.</p>
        </body>
      </html>
    """;
  }

  Future<void> _refreshContent() async {
    setState(() => _isLoading = true);
    await _loadHtmlContent();
  }

  void _openEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusinessEditPage(
          businessName: widget.businessName,
          onSaved: _refreshContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            icon: const Icon(Icons.edit),
            onPressed: _openEditPage,
            tooltip: 'Edit Page',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshContent,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: kIsWeb
          ? SingleChildScrollView(
              child: HtmlWidget(_htmlContent ?? ''),
            )
          : _MobileWebView(html: _htmlContent ?? ''),
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

// ================== Edit Page ==================
class BusinessEditPage extends StatefulWidget {
  final String businessName;
  final VoidCallback onSaved;

  const BusinessEditPage({
    super.key,
    required this.businessName,
    required this.onSaved,
  });

  @override
  State<BusinessEditPage> createState() => _BusinessEditPageState();
}

class _BusinessEditPageState extends State<BusinessEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  
  // Form controllers with default values from test.html
  final _titleController = TextEditingController(text: 'Rainforest Rooftop Bar');
  final _descriptionController = TextEditingController(text: 'Perfect spot for sundowner and panoramic Bangkok skyline views');
  final _addressController = TextEditingController(text: 'Soi Sukhumvit 15 Khlong Toei Nuea Subdistrict Wattana District Bangkok 10110');
  final _phoneController = TextEditingController(text: '+6621193100');
  final _imageUrlController = TextEditingController(text: 'https://customercallsapp.com/prod/customercallsapp/business_images/Rainforest-rooftop-bar.jpg');
  final _aboutController = TextEditingController(text: 'Perfect spot for sundowner and panoramic Bangkok skyline views');
  final _happyHourTimeController = TextEditingController(text: '15:00:00 – 19:00:00');
  final _happyHourNoteController = TextEditingController(text: 'Except Friday-Saturday');
  final _dressCodeController = TextEditingController(text: 'Casual');
  final _facilitiesController = TextEditingController(text: 'Rooftop pool, petanque strip, kids play area, outdoor seating');
  final _goodToKnowController = TextEditingController(text: 'Family-friendly, stunning skyline views, open daily');
  final _paymentMethodsController = TextEditingController(text: 'Credit cards accepted');
  
  Map<String, Map<String, String>> _openingHours = {
    'Monday': {'open': '9:00:00', 'close': '23:30:00'},
    'Tuesday': {'open': '9:00:00', 'close': '23:30:00'},
    'Wednesday': {'open': '9:00:00', 'close': '23:30:00'},
    'Thursday': {'open': '9:00:00', 'close': '23:30:00'},
    'Friday': {'open': '9:00:00', 'close': '23:30:00'},
    'Saturday': {'open': '9:00:00', 'close': '23:30:00'},
    'Sunday': {'open': '9:00:00', 'close': '23:30:00'},
  };

  @override
  void initState() {
    super.initState();
    // Load data in background without blocking UI
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    try {
      final response = await http.get(
        Uri.parse('https://app.lovehappyhours.com/happy-hours-api/get_page_data/${widget.businessName}'),
      ).timeout(const Duration(seconds: 3)); // Add timeout

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            if (data['title'] != null) _titleController.text = data['title'];
            if (data['description'] != null) _descriptionController.text = data['description'];
            if (data['address'] != null) _addressController.text = data['address'];
            if (data['phone'] != null) _phoneController.text = data['phone'];
            if (data['image_url'] != null) _imageUrlController.text = data['image_url'];
            if (data['about'] != null) _aboutController.text = data['about'];
            if (data['happy_hour_time'] != null) _happyHourTimeController.text = data['happy_hour_time'];
            if (data['happy_hour_note'] != null) _happyHourNoteController.text = data['happy_hour_note'];
            if (data['dress_code'] != null) _dressCodeController.text = data['dress_code'];
            if (data['facilities'] != null) _facilitiesController.text = data['facilities'];
            if (data['good_to_know'] != null) _goodToKnowController.text = data['good_to_know'];
            if (data['payment_methods'] != null) _paymentMethodsController.text = data['payment_methods'];
            
            if (data['opening_hours'] != null) {
              _openingHours = Map<String, Map<String, String>>.from(
                data['opening_hours'].map((key, value) => 
                  MapEntry(key, Map<String, String>.from(value))
                )
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading data (using defaults): $e');
      // Continue with default values - no error shown to user
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('https://app.lovehappyhours.com/happy-hours-api/update_page'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "business_name": widget.businessName,
          "title": _titleController.text,
          "description": _descriptionController.text,
          "address": _addressController.text,
          "phone": _phoneController.text,
          "image_url": _imageUrlController.text,
          "about": _aboutController.text,
          "happy_hour_time": _happyHourTimeController.text,
          "happy_hour_note": _happyHourNoteController.text,
          "dress_code": _dressCodeController.text,
          "facilities": _facilitiesController.text,
          "good_to_know": _goodToKnowController.text,
          "payment_methods": _paymentMethodsController.text,
          "opening_hours": _openingHours,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Changes saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          widget.onSaved();
          Navigator.pop(context);
        } else {
          throw Exception(data['message'] ?? 'Failed to save');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _imageUrlController.dispose();
    _aboutController.dispose();
    _happyHourTimeController.dispose();
    _happyHourNoteController.dispose();
    _dressCodeController.dispose();
    _facilitiesController.dispose();
    _goodToKnowController.dispose();
    _paymentMethodsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Removed loading check - show form immediately with default values
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Business Page', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6a0dad),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Business Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aboutController,
              decoration: const InputDecoration(
                labelText: 'About',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _happyHourTimeController,
              decoration: const InputDecoration(
                labelText: 'Happy Hour Time (e.g., 15:00:00 – 19:00:00)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _happyHourNoteController,
              decoration: const InputDecoration(
                labelText: 'Happy Hour Note',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dressCodeController,
              decoration: const InputDecoration(
                labelText: 'Dress Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.checkroom),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facilitiesController,
              decoration: const InputDecoration(
                labelText: 'Facilities',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_activity),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _goodToKnowController,
              decoration: const InputDecoration(
                labelText: 'Good to Know',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lightbulb),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paymentMethodsController,
              decoration: const InputDecoration(
                labelText: 'Payment Methods',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6a0dad),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}