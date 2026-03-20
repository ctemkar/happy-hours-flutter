import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BusinessRegistrationPage extends StatefulWidget {
  const BusinessRegistrationPage({super.key});

  @override
  State<BusinessRegistrationPage> createState() => _BusinessRegistrationPageState();
}

class _BusinessRegistrationPageState extends State<BusinessRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController openHoursController = TextEditingController();
  final TextEditingController happyHourStartController = TextEditingController();
  final TextEditingController happyHourEndController = TextEditingController();
  final TextEditingController happyHoursYesNoController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Business categories support
  final List<String> businessCategories = <String>[
    'Bar',
    'Pub',
    'Cafe',
    'Restaurant',
    'Lounge',
    'Brewery',
    'Wine Bar',
    'Club',
    'Hotel Bar',
    'Sports Bar',
    'Rooftop',
    'Other',
  ];
  String? selectedCategory;

  Future<void> registerBusiness() async {
    final uri = Uri.parse("https://app.lovehappyhours.com/happy-hours-api/business_registration");
    
    final body = {
      "businessName": businessNameController.text,
      "ownerName": nameController.text,
      "email": emailController.text,
      "phone": phoneController.text,
      "password": passwordController.text,
      "address": addressController.text,
      "city": cityController.text,
      "state": stateController.text,
      "country": countryController.text,
      "pin": pinController.text,
      "category": categoryController.text,
      "description": descriptionController.text,
      "open_hours": openHoursController.text,
      "happy_hour_start": happyHourStartController.text,
      "happy_hour_end": happyHourEndController.text,
      "happy_hour_yes_no": happyHoursYesNoController.text,
      "remark": remarkController.text,
      "latitude": latitudeController.text,
      "longitude": longitudeController.text,
    };

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Server responded.")),
        );

        // Clear form on success
        if (data['status'] == 'success') {
          _formKey.currentState?.reset();
          nameController.clear();
          emailController.clear();
          phoneController.clear();
          passwordController.clear();
          confirmPasswordController.clear();
          businessNameController.clear();
          categoryController.clear();
          selectedCategory = null;
          descriptionController.clear();
          addressController.clear();
          cityController.clear();
          countryController.clear();
          stateController.clear();
          pinController.clear();
          openHoursController.clear();
          happyHourStartController.clear();
          happyHourEndController.clear();
          happyHoursYesNoController.clear();
          remarkController.clear();
          latitudeController.clear();
          longitudeController.clear();
          setState(() {});
        }
      } else {
        // Improved error parsing to display backend message
        String serverMsg = "Server error: ${response.statusCode}";
        try {
          final data = json.decode(response.body);
          if (data is Map && data['message'] != null) {
            serverMsg = data['message'].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(serverMsg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Auto-geocoding using OpenStreetMap Nominatim (no key required).
  Future<Map<String, String>?> _geocodeFromAddress({
    required String address,
    required String city,
    String? state,
    String? country,
    String? pin,
  }) async {
    try {
      final q = [
        address,
        if (city.isNotEmpty) city,
        if (state != null && state.isNotEmpty) state,
        if (country != null && country.isNotEmpty) country,
        if (pin != null && pin.isNotEmpty) pin,
      ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

      if (q.isEmpty) return null;

      final uri = Uri.parse("https://nominatim.openstreetmap.org/search").replace(queryParameters: {
        "q": q,
        "format": "json",
        "limit": "1",
      });

      final res = await http.get(
        uri,
        headers: {
          "User-Agent": "HappyHoursApp/1.0 (contact: support@lovehappyhours.com)",
        },
      );

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          final lat = first["lat"]?.toString();
          final lon = first["lon"]?.toString();
          if (lat != null && lon != null) {
            return {"lat": lat, "lon": lon};
          }
        }
      }
    } catch (_) {
      // Ignore and let caller proceed without coordinates
    }
    return null;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    businessNameController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    cityController.dispose();
    countryController.dispose();
    stateController.dispose();
    pinController.dispose();
    openHoursController.dispose();
    happyHourStartController.dispose();
    happyHourEndController.dispose();
    happyHoursYesNoController.dispose();
    remarkController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Registration", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6a0dad),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFFfdfbff),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Register Your Business",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6a0dad),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                _buildTextField(controller: nameController, label: "Full Name", icon: Icons.person),
                _buildTextField(controller: emailController, label: "Email", icon: Icons.email, keyboardType: TextInputType.emailAddress),
                _buildTextField(controller: phoneController, label: "Phone", icon: Icons.phone, keyboardType: TextInputType.phone),

                // Password field
                _buildPasswordField(
                  controller: passwordController,
                  label: "Password",
                  icon: Icons.lock,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),

                // Confirm Password field
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: "Confirm Password",
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm your password";
                    }
                    if (value != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),

                const Divider(),

                _buildTextField(controller: businessNameController, label: "Business Name", icon: Icons.store),

                // Business Category with tooltip + dropdown + validator
                _buildCategoryField(),

                _buildTextField(controller: descriptionController, label: "Business Description", icon: Icons.description),
                _buildTextField(controller: addressController, label: "Address", icon: Icons.location_on),
                _buildTextField(controller: cityController, label: "City", icon: Icons.location_city),
                _buildTextField(controller: countryController, label: "Country", icon: Icons.flag),
                _buildTextField(controller: stateController, label: "State", icon: Icons.map),
                _buildTextField(controller: pinController, label: "PIN Code", icon: Icons.pin, keyboardType: TextInputType.number),

                const Divider(),

                _buildTextField(controller: openHoursController, label: "Open Hours", icon: Icons.access_time),
                _buildTextField(controller: happyHourStartController, label: "Happy Hour Start", icon: Icons.timer),
                _buildTextField(controller: happyHourEndController, label: "Happy Hour End", icon: Icons.timer_off),

                // Happy Hours Available (1/0) with tooltip and validation
                _buildHappyHoursField(),

                _buildTextField(controller: remarkController, label: "Remarks", icon: Icons.note),

                const Divider(),

                // Latitude/Longitude optional
                _buildTextField(
                  controller: latitudeController,
                  label: "Latitude (optional)",
                  icon: Icons.my_location,
                  validator: (_) => null,
                ),
                _buildTextField(
                  controller: longitudeController,
                  label: "Longitude (optional)",
                  icon: Icons.location_searching,
                  validator: (_) => null,
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Attempt geocoding if coordinates not provided
                      if (latitudeController.text.isEmpty || longitudeController.text.isEmpty) {
                        final result = await _geocodeFromAddress(
                          address: addressController.text,
                          city: cityController.text,
                          state: stateController.text,
                          country: countryController.text,
                          pin: pinController.text,
                        );
                        if (result != null) {
                          latitudeController.text = result["lat"]!;
                          longitudeController.text = result["lon"]!;
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Could not auto-detect location from address. Proceeding without coordinates.")),
                          );
                        }
                      }
                      await registerBusiness();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6a0dad),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6a0dad)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF6a0dad), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: validator ?? (value) => value == null || value.isEmpty ? "Please enter $label" : null,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF6a0dad)),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF6a0dad),
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF6a0dad), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          if (value.length < 6) {
            return "Password must be at least 6 characters";
          }
          return null;
        },
      ),
    );
  }

  // Category field with tooltip and validation
  Widget _buildCategoryField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FormField<String>(
        validator: (_) {
          if ((categoryController.text).trim().isEmpty) {
            return "Please select Business Category";
          }
          return null;
        },
        builder: (state) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: "Business Category",
              prefixIcon: const Icon(Icons.category, color: Color(0xFF6a0dad)),
              suffixIcon: Tooltip(
                message: businessCategories.join(', '),
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(Icons.info_outline, color: Color(0xFF6a0dad)),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF6a0dad), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: state.errorText,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedCategory,
                hint: const Text("Select a category"),
                items: businessCategories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCategory = val;
                    categoryController.text = val ?? '';
                    state.didChange(val);
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Happy Hours Available field 1/0 with tooltip and validation
  Widget _buildHappyHoursField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: happyHoursYesNoController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: "Happy Hours Available (1 for Yes, 0 for No)",
          prefixIcon: const Icon(Icons.event_available, color: Color(0xFF6a0dad)),
          suffixIcon: const Tooltip(
            message: "Enter 1 for Yes, 0 for No",
            triggerMode: TooltipTriggerMode.tap,
            child: Icon(Icons.info_outline, color: Color(0xFF6a0dad)),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF6a0dad), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Please enter Happy Hours Available";
          if (value != '0' && value != '1') return "Only 1 (Yes) or 0 (No) allowed";
          return null;
        },
      ),
    );
  }
}