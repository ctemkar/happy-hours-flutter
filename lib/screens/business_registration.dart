import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();

  File? businessPhoto;
  File? licensePhoto;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isBusinessPhoto) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isBusinessPhoto) {
          businessPhoto = File(picked.path);
        } else {
          licensePhoto = File(picked.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Registration",
        style: TextStyle(color: Colors.white),),
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

                // Owner Details
                _buildTextField(controller: nameController, label: "Full Name", icon: Icons.person),
                _buildTextField(controller: emailController, label: "Email", icon: Icons.email, keyboardType: TextInputType.emailAddress),
                _buildTextField(controller: phoneController, label: "Phone", icon: Icons.phone, keyboardType: TextInputType.phone),

                const SizedBox(height: 10),
                const Divider(),

                // Business Details
                _buildTextField(controller: businessNameController, label: "Business Name", icon: Icons.store),
                _buildTextField(controller: categoryController, label: "Business Category", icon: Icons.category),
                _buildTextField(controller: addressController, label: "Address", icon: Icons.location_on),
                _buildTextField(controller: cityController, label: "City", icon: Icons.location_city),
                _buildTextField(controller: stateController, label: "State", icon: Icons.map),
                _buildTextField(controller: pinController, label: "PIN Code", icon: Icons.pin, keyboardType: TextInputType.number),

                const SizedBox(height: 10),
                const Divider(),

                // Location
                _buildTextField(controller: latitudeController, label: "Latitude (optional)", icon: Icons.my_location),
                _buildTextField(controller: longitudeController, label: "Longitude (optional)", icon: Icons.location_searching),

                const SizedBox(height: 10),
                const Divider(),

                // Upload Photos
                _buildFilePicker("Upload Business Photo", businessPhoto, () => _pickImage(true)),
                _buildFilePicker("Upload Legal Document", licensePhoto, () => _pickImage(false)),

                const SizedBox(height: 30),

                // Register Button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Business Registered Successfully!")),
                      );
                      // TODO: send data + files to PHP backend
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6a0dad),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

  // Text Field Widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
      ),
    );
  }

  // File Upload Widget
  Widget _buildFilePicker(String label, File? file, VoidCallback onPick) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6a0dad))),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onPick,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6a0dad),
              ),
              icon: const Icon(Icons.upload, color: Colors.white),
              label: const Text("Choose File", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file != null ? file.path.split('/').last : "No file selected",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
