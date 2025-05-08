import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class HelpRequestPage extends StatefulWidget {
  @override
  _HelpRequestPageState createState() => _HelpRequestPageState();
}

class _HelpRequestPageState extends State<HelpRequestPage> {
  final _formKey = GlobalKey<FormState>();  // Global key for form validation
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

  Future<void> _getLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text = 'Latitude: $_latitude, Longitude: $_longitude'; // Auto-filled location
      });
    } else {
      print('Location permission denied');
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState?.validate() ?? false) {  // Validate form
      // If form is valid, submit to Firestore
      await FirebaseFirestore.instance.collection('requests').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'urgency': _selectedUrgency,
        'latitude': _latitude,
        'longitude': _longitude,
        'location': _locationController.text, // Store manually typed location
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request submitted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit a Help Request'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,  // Associate the form with the key
          child: ListView(
            children: [
              // Request Title Input with Validation
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Request Title',
                  hintText: 'Enter the title of the request',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for the request';
                  }
                  return null;  // Valid input
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                maxLines: 4,  // Allow multiple lines for the description
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;  // Valid input
                },
              ),
              SizedBox(height: 20),

              // Category Dropdown with Validation
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  isExpanded: true,
                  items: <String>['Groceries', 'Transport', 'Companionship', 'Medication', 'Other']
                      .map<DropdownMenuItem<String>>((String value) {
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: DropdownButton<String>(
                  value: _selectedUrgency,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUrgency = newValue!;
                    });
                  },
                  isExpanded: true,
                  items: <String>['Low', 'Medium', 'High']
                      .map<DropdownMenuItem<String>>((String value) {
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a location';
                  }
                  return null;  // Valid input
                },
              ),
              SizedBox(height: 20),

              // Submit Button with Style
              ElevatedButton(
                onPressed: _submitRequest,
                child: Text('Submit Request'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Button color
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
