import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'dart:typed_data';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<BusinessRegistrationScreen> createState() =>
      _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState
    extends State<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _openHoursController = TextEditingController();
  final TextEditingController _happyHourStartController = TextEditingController();
  final TextEditingController _happyHourEndController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _mapLinkController = TextEditingController();

  // Dropdown values
  String? _selectedCategory;
  String _happyHourYesNo = "1";

  // Image picker
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  // ✅ Validation error messages for dynamic display
  String? _openHoursError;
  String? _happyHourStartError;
  String? _happyHourEndError;
  String? _happyHourYesNoError;

  final List<String> _categories = [
    'Bar',
    'Cafe',
    'Club',
    'Fast Food',
    'Massage',
    'Night Club',
    'Restaurant',
    'Spa'
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    _openHoursController.dispose();
    _happyHourStartController.dispose();
    _happyHourEndController.dispose();
    _remarkController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _mapLinkController.dispose();
    super.dispose();
  }

  // ✅ Helper: Convert a "HH:mm" or "hh:mm AM/PM" string to minutes since midnight
  int? _parseTimeToMinutes(String? timeText) {
    if (timeText == null || timeText.trim().isEmpty) return null;

    try {
      final time = timeText.trim().toUpperCase();
      final match = RegExp(r'(\d{1,2}):(\d{2})(?:\s*(AM|PM))?').firstMatch(time);
      if (match == null) return null;

      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      String? period = match.group(3);

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return hour * 60 + minute;
    } catch (e) {
      return null;
    }
  }

  // ✅ Extract open hours "All Days 10:30 - 20:30" into start and end
  Map<String, int?> _extractOpenHoursRange(String text) {
    final match = RegExp(r'(\d{1,2}:\d{2}).*?(\d{1,2}:\d{2})').firstMatch(text);
    if (match == null) return {'start': null, 'end': null};
    return {
      'start': _parseTimeToMinutes(match.group(1)),
      'end': _parseTimeToMinutes(match.group(2)),
    };
  }

  // ✅ Live validation for Happy Hour times vs Open Hours
  void _validateHappyHourTimes() {
    final openHours = _openHoursController.text.trim();
    final happyStart = _happyHourStartController.text.trim();
    final happyEnd = _happyHourEndController.text.trim();

    // Reset errors
    setState(() {
      _openHoursError = null;
      _happyHourStartError = null;
      _happyHourEndError = null;
    });

    if (openHours.isEmpty || happyStart.isEmpty || happyEnd.isEmpty) return;

    final openRange = _extractOpenHoursRange(openHours);
    final openStart = openRange['start'];
    final openEnd = openRange['end'];
    final happyStartMins = _parseTimeToMinutes(happyStart);
    final happyEndMins = _parseTimeToMinutes(happyEnd);

    if (openStart == null || openEnd == null || happyStartMins == null || happyEndMins == null) {
      return;
    }

    if (happyStartMins < openStart) {
      setState(() {
        _happyHourStartError = 'Happy Hour Start is before opening time';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Happy Hour Start is before opening time'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (happyEndMins > openEnd) {
      setState(() {
        _happyHourEndError = 'Happy Hour End is after closing time';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Happy Hour End is after closing time'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (happyEndMins <= happyStartMins) {
      setState(() {
        _happyHourEndError = 'Happy Hour End must be after Start';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Happy Hour End must be after Start'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ✅ Live validation for Happy Hour Yes/No field
  void _validateHappyHourYesNoField() {
    final happyYesNo = _happyHourYesNo;
    final happyStart = _happyHourStartController.text.trim();
    final happyEnd = _happyHourEndController.text.trim();

    setState(() {
      _happyHourYesNoError = null;
      _happyHourStartError = null;
      _happyHourEndError = null;
    });

    if (happyYesNo == '0') {
      // Case: user says "No" but entered times
      if (happyStart.isNotEmpty || happyEnd.isNotEmpty) {
        setState(() {
          _happyHourYesNoError = 'You selected No but entered times';
          _happyHourStartError = 'Remove this if Happy Hour is No';
          _happyHourEndError = 'Remove this if Happy Hour is No';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ You selected No for Happy Hours, but entered times.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (happyYesNo == '1') {
      // Case: user says "Yes" but missing times
      if (happyStart.isEmpty && happyEnd.isEmpty) {
        setState(() {
          _happyHourStartError = 'Required when Happy Hour is Yes';
          _happyHourEndError = 'Required when Happy Hour is Yes';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Happy Hour Start and End times are required when selected Yes.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (happyStart.isEmpty) {
        setState(() {
          _happyHourStartError = 'Required when Happy Hour is Yes';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Happy Hour Start is required when selected Yes.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (happyEnd.isEmpty) {
        setState(() {
          _happyHourEndError = 'Required when Happy Hour is Yes';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Happy Hour End is required when selected Yes.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ✅ Combined validation trigger
  void _runAllHappyHourValidations() {
    _validateHappyHourYesNoField();
    _validateHappyHourTimes();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = pickedFile;
          _imageBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selected successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
    });
  }

  Future<void> _registerBusiness() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // ✅ Run happy hour validation before registration
    final happyYesNo = _happyHourYesNo;
    final happyStart = _happyHourStartController.text.trim();
    final happyEnd = _happyHourEndController.text.trim();
    final openHours = _openHoursController.text.trim();

    if (happyYesNo == '0' && (happyStart.isNotEmpty || happyEnd.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You selected No for Happy Hours, but entered times.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } else if (happyYesNo == '1') {
      if (happyStart.isEmpty || happyEnd.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter both Happy Hour Start and End times when Yes is selected.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // ✅ Time range validation
    if (openHours.isNotEmpty && happyStart.isNotEmpty && happyEnd.isNotEmpty) {
      final openRange = _extractOpenHoursRange(openHours);
      final openStart = openRange['start'];
      final openEnd = openRange['end'];
      final happyStartMins = _parseTimeToMinutes(happyStart);
      final happyEndMins = _parseTimeToMinutes(happyEnd);

      if (openStart != null &&
          openEnd != null &&
          happyStartMins != null &&
          happyEndMins != null) {
        if (happyStartMins < openStart) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Happy Hour Start cannot be before Opening Time!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        } else if (happyEndMins > openEnd) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Happy Hour End cannot be after Closing Time!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        } else if (happyEndMins <= happyStartMins) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Happy Hour End must be after Start time!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://app.lovehappyhours.com/happy-hours-api/business_registration'),
      );

      request.fields['businessName'] = _businessNameController.text.trim();
      request.fields['ownerName'] = _ownerNameController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['password'] = _passwordController.text;
      request.fields['address'] = _addressController.text.trim();
      request.fields['city'] = _cityController.text.trim();
      request.fields['state'] = _stateController.text.trim();
      request.fields['pin'] = _pinController.text.trim();
      request.fields['country'] = _countryController.text.trim();
      request.fields['category'] = _selectedCategory ?? '';
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['open_hours'] = _openHoursController.text.trim();
      request.fields['happy_hour_start'] = _happyHourStartController.text.trim();
      request.fields['happy_hour_end'] = _happyHourEndController.text.trim();
      request.fields['happy_hour_yes_no'] = _happyHourYesNo;
      request.fields['remark'] = _remarkController.text.trim();
      request.fields['latitude'] = _latitudeController.text.trim();
      request.fields['longitude'] = _longitudeController.text.trim();
      request.fields['google_marker'] = _mapLinkController.text.trim();

      // Add image file
      if (_selectedImage != null && _imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'business_image',
            _imageBytes!,
            filename: _selectedImage!.name,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        
        if (jsonResponse['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(jsonResponse['message'] ?? 'Registration successful!'),
                backgroundColor: Colors.green,
              ),
            );
            
            _formKey.currentState!.reset();
            _businessNameController.clear();
            _ownerNameController.clear();
            _emailController.clear();
            _phoneController.clear();
            _passwordController.clear();
            _addressController.clear();
            _cityController.clear();
            _stateController.clear();
            _pinController.clear();
            _countryController.clear();
            _descriptionController.clear();
            _openHoursController.clear();
            _happyHourStartController.clear();
            _happyHourEndController.clear();
            _remarkController.clear();
            _latitudeController.clear();
            _longitudeController.clear();
            _mapLinkController.clear();
            setState(() {
              _selectedCategory = null;
              _happyHourYesNo = "1";
              _selectedImage = null;
              _imageBytes = null;
              _openHoursError = null;
              _happyHourStartError = null;
              _happyHourEndError = null;
              _happyHourYesNoError = null;
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(jsonResponse['message'] ?? 'Registration failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text(
          'Business Registration',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Business Name
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Business name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Owner Name
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Owner Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Owner name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
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

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
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

              // City
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // State
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
              ),
              const SizedBox(height: 16),

              // Pin
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Country
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ✅ Business Image Upload Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        const Text(
                          'Business Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_imageBytes != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _imageBytes!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _removeImage,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No image selected',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload),
                      label: Text(_selectedImage == null ? 'Select Image' : 'Change Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    const Text(
                      'Supported formats: JPG, PNG, GIF, WEBP',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // ✅ Open Hours with live validation trigger
              TextFormField(
                controller: _openHoursController,
                decoration: InputDecoration(
                  labelText: 'Open Hours',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _openHoursError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _openHoursError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _openHoursError != null ? Colors.red : Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.access_time,
                    color: _openHoursError != null ? Colors.red : null,
                  ),
                  hintText: 'e.g., All Days 10:30 - 20:30',
                  errorText: _openHoursError,
                ),
                onChanged: (_) => _runAllHappyHourValidations(),
              ),
              const SizedBox(height: 16),

              // ✅ Happy Hour Start with live validation and red border
              TextFormField(
                controller: _happyHourStartController,
                decoration: InputDecoration(
                  labelText: 'Happy Hour Start',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _happyHourStartError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _happyHourStartError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _happyHourStartError != null ? Colors.red : Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.schedule,
                    color: _happyHourStartError != null ? Colors.red : null,
                  ),
                  hintText: 'e.g., 5:00 PM',
                  errorText: _happyHourStartError,
                ),
                onChanged: (_) => _runAllHappyHourValidations(),
              ),
              const SizedBox(height: 16),

              // ✅ Happy Hour End with live validation and red border
              TextFormField(
                controller: _happyHourEndController,
                decoration: InputDecoration(
                  labelText: 'Happy Hour End',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _happyHourEndError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _happyHourEndError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _happyHourEndError != null ? Colors.red : Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.schedule,
                    color: _happyHourEndError != null ? Colors.red : null,
                  ),
                  hintText: 'e.g., 7:00 PM',
                  errorText: _happyHourEndError,
                ),
                onChanged: (_) => _runAllHappyHourValidations(),
              ),
              const SizedBox(height: 16),

              // ✅ Happy Hour Yes/No with live validation and red border
              DropdownButtonFormField<String>(
                value: _happyHourYesNo,
                decoration: InputDecoration(
                  labelText: 'Happy Hour Available',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _happyHourYesNoError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _happyHourYesNoError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _happyHourYesNoError != null ? Colors.red : Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    Icons.celebration,
                    color: _happyHourYesNoError != null ? Colors.red : null,
                  ),
                  suffixIcon: const Icon(Icons.info_outline, size: 20),
                  errorText: _happyHourYesNoError,
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: '1',
                    child: Text('1 (Yes)'),
                  ),
                  DropdownMenuItem<String>(
                    value: '0',
                    child: Text('0 (No)'),
                  ),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _happyHourYesNo = newValue ?? '1';
                  });
                  _runAllHappyHourValidations();
                },
              ),
              const SizedBox(height: 16),

              // Remark
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(
                  labelText: 'Remark',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Latitude
              TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.my_location),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Longitude
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.my_location),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Map Link (Google Marker)
              TextFormField(
                controller: _mapLinkController,
                decoration: const InputDecoration(
                  labelText: 'Map Link (Google Maps URL)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map_outlined),
                  hintText: 'Paste Google Maps link here',
                ),
              ),

              const SizedBox(height: 24),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _registerBusiness,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Register Business'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}