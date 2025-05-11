import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'help_forum.dart';

class HelpRequestPage extends StatefulWidget {
  @override
  _HelpRequestPageState createState() => _HelpRequestPageState();
}

class _HelpRequestPageState extends State<HelpRequestPage> {
  final _formKey = GlobalKey<FormState>(); // Global key for form validation
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _locationController = TextEditingController();

  String _selectedCategory = 'Groceries';
  String _selectedUrgency = 'Low';

  double? _latitude, _longitude;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  // Fetch current location using Geolocator and handle permission
  Future<void> _getLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text =
            'Latitude: $_latitude, Longitude: $_longitude'; // Auto-filled location
      });
    } else {
      print('Location permission denied');
    }
  }

  // Submit the help request to Firestore
  Future<void> _submitRequest() async {
    if (_formKey.currentState?.validate() ?? false) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User is not authenticated')));
        return;
      }

      String userUid = currentUser.uid; // Get the Firebase Authentication UID (auto-generated)
      String userEmail = currentUser.email ?? ''; // Get the email of the current user

      // Fetch the userName using the userId
      String userName = '';
      try {
        // Fetch userName from Firestore (from the 'users' collection)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userUid)
            .get();

        // If userName exists, use it; otherwise, default to 'Anonymous User'
        userName = userDoc['username'] ?? 'Anonymous User';

        // Add the help request to the 'requests' subcollection under the user's document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userUid) // Use the Firebase Auth UID directly as the document ID
            .collection('requests')
            .add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          'urgency': _selectedUrgency,
          'latitude': _latitude,
          'longitude': _longitude,
          'location': _locationController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'volunteerName': '', // Initially empty as no volunteer has accepted the request
          'volunteerAccepted': false,
          'userEmail': userEmail, // Store the email along with the request
          'userId': userUid,    // Store the unique userId
          'userName': userName, // Store the userName fetched from Firestore
        });

        // Clear the form fields after submission
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        setState(() {
          _selectedCategory = 'Groceries'; // Reset category dropdown
          _selectedUrgency = 'Low'; // Reset urgency dropdown
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request submitted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Submit a Help Request',style: GoogleFonts.comicNeue(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: Colors.deepOrange,
        ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HelpForumPage()),
            ); // Navigate to MainPage
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Associate the form with the key
          child: ListView(
            children: [
              // Request Title Input with Validation
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Request Title',
                  hintText: 'Enter the title of the request',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for the request';
                  }
                  return null; // Valid input
                },
              ),
              SizedBox(height: 20),

              // Description Input with Validation
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide more details about the request',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                maxLines: 4, // Allow multiple lines for the description
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null; // Valid input
                },
              ),
              SizedBox(height: 20),

              // Category Dropdown with Validation
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  isExpanded: true,
                  items:
                      <String>[
                        'Groceries',
                        'Transport',
                        'Companionship',
                        'Medication',
                        'Other',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
              ),
              SizedBox(height: 20),

              // Urgency Dropdown with Validation
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Urgency',
                  prefixIcon: Icon(Icons.priority_high),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedUrgency,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUrgency = newValue!;
                    });
                  },
                  isExpanded: true,
                  items:
                      <String>[
                        'Low',
                        'Medium',
                        'High',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
              ),
              SizedBox(height: 20),

              // Location Input with Validation
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location (auto-filled or type manually)',
                  hintText: 'Type location manually if needed',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a location';
                  }
                  return null; // Valid input
                },
              ),
              SizedBox(height: 20),

              // Submit Button with Style
              ElevatedButton(
                onPressed: _submitRequest,
                child: Text(
                  'Submit Request',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 20),

              // Show current location if available
              if (_latitude != null && _longitude != null)
                Text(
                  'Auto-filled Location: $_latitude, $_longitude',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
