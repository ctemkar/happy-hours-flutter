import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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

  Future<void> registerBusiness() async {
  var uri = Uri.parse("https://customercallsapp.com/prod/customercallsapp/business_registration.php");

  var request = http.MultipartRequest("POST", uri);

  // Add text fields
  request.fields['ownerName']       = nameController.text;
  request.fields['email']           = emailController.text;
  request.fields['phone']           = phoneController.text;
  request.fields['businessName']    = businessNameController.text;
  request.fields['category']        = categoryController.text;
  request.fields['description']     = descriptionController.text;
  request.fields['address']         = addressController.text;
  request.fields['city']            = cityController.text;
  request.fields['country']         = countryController.text;
  request.fields['state']           = stateController.text;
  request.fields['pin']             = pinController.text;
  request.fields['open_hours']      = openHoursController.text;
  request.fields['happy_hour_start']= happyHourStartController.text;
  request.fields['happy_hour_end']  = happyHourEndController.text;
  request.fields['happy_hour_yes_no']= happyHoursYesNoController.text;
  request.fields['remark']          = remarkController.text;
  request.fields['latitude']        = latitudeController.text;
  request.fields['longitude']       = longitudeController.text;

  // Add file uploads if present
  if (businessPhoto != null) {
    request.files.add(await http.MultipartFile.fromPath("photo", businessPhoto!.path));
  }
  if (licensePhoto != null) {
    request.files.add(await http.MultipartFile.fromPath("license", licensePhoto!.path));
  }

  // Send request
  var response = await request.send();

  if (response.statusCode == 200) {
    var responseBody = await response.stream.bytesToString();
    print("Response: $responseBody");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Business Registered! Verification email sent.")),
    );
  } else {
    print("Failed with status: ${response.statusCode}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registration failed. Try again.")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Business Registration",
          style: TextStyle(color: Colors.white),
        ),
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

                const Divider(),

                // Business Details
                _buildTextField(controller: businessNameController, label: "Business Name", icon: Icons.store),
                _buildTextField(controller: categoryController, label: "Business Category", icon: Icons.category),
                _buildTextField(controller: descriptionController, label: "Business Description", icon: Icons.description, keyboardType: TextInputType.multiline,
),              _buildTextField(controller: addressController, label: "Address", icon: Icons.location_on),
                _buildTextField(controller: cityController, label: "City", icon: Icons.location_city),
                _buildTextField(controller: countryController, label: "Country", icon: Icons.flag),
                _buildTextField(controller: stateController, label: "State", icon: Icons.map),
                _buildTextField(controller: pinController, label: "PIN Code", icon: Icons.pin, keyboardType: TextInputType.number),

                const Divider(),

                // Hours
                _buildTextField(controller: openHoursController, label: "Open Hours", icon: Icons.access_time),
                _buildTextField(controller: happyHourStartController, label: "Happy Hour Start", icon: Icons.timer),
                _buildTextField(controller: happyHourEndController, label: "Happy Hour End", icon: Icons.timer_off),
                _buildTextField(controller: happyHoursYesNoController, label: "Happy Hours Available (Yes/No)", icon: Icons.event_available),
                _buildTextField(controller: remarkController, label: "Remarks", icon: Icons.note),

                const Divider(),

                // Location
                _buildTextField(controller: latitudeController, label: "Latitude", icon: Icons.my_location),
                _buildTextField(controller: longitudeController, label: "Longitude", icon: Icons.location_searching),

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
                        const SnackBar(content: Text("Business Registered Successfully! Verification email sent.")),
                      );
                      // TODO: Send data + files to PHP backend
                      // TODO: PHP will send verification email with link
                      registerBusiness();
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6a0dad)),
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
