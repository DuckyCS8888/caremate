import 'package:flutter/material.dart';
import 'package:projects/volunteer_request.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestDetailPage extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final String urgency;
  final num latitude;
  final num longitude;
  final String location;
  final String requestId; // Added requestId to uniquely identify the request

  RequestDetailPage({
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.requestId,  // Pass requestId as a parameter
  });

  @override
  _RequestDetailPageState createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  bool _isVolunteerAccepted = false;
  String _volunteerName = '';

  @override
  void initState() {
    super.initState();
    _checkIfAccepted();
  }

  // Method to open Google Maps directions
  Future<void> _openGoogleMaps() async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${widget.latitude},${widget.longitude}';
    final Uri uri = Uri.parse(url); // Convert string URL into Uri

    // Check if the URL can be launched
    if (await canLaunchUrl(uri)) {
      // Launch the URL based on whether you want to use WebView or the default browser
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,  // Use the default browser
      );
    } else {
      throw 'Could not launch $url'; // Error if URL can't be opened
    }
  }

  // Function to check if the request has already been accepted
  Future<void> _checkIfAccepted() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final requestDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid) // Get the current user's document
          .collection('requests') // Access the subcollection
          .doc(widget.requestId) // Use the requestId
          .get();

      if (requestDoc.exists) {
        setState(() {
          _isVolunteerAccepted = requestDoc['volunteerAccepted'] ?? false;
          _volunteerName = requestDoc['volunteerName'] ?? '';
        });
      }
    } catch (e) {
      print('Error checking request status: $e');
    }
  }

  // Function to accept the request
  Future<void> _acceptRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You must be logged in to accept a request')));
      return;
    }

    // Retrieve the volunteer's username
    String volunteerName = await _getUsername(currentUser.uid);  // Retrieve username

    try {
      // Update the request document using requestId to mark it as accepted and add volunteer details (email as contact)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid) // Get the current user's document
          .collection('requests') // Access the user's 'requests' subcollection
          .doc(widget.requestId) // Update the specific request by ID
          .update({
        'volunteerName': volunteerName,  // Set the volunteer's name to their username
        'volunteerAccepted': true,  // Mark the request as accepted
      });

      setState(() {
        _isVolunteerAccepted = true;
        _volunteerName = volunteerName;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You have successfully accepted the request')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error accepting request: $e')));
    }
  }

  // Helper method to retrieve the username from Firestore
  Future<String> _getUsername(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      return userDoc['username'] ?? 'Unknown';  // Return 'Unknown' if the username doesn't exist
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Details'),
        backgroundColor: Colors.orange,
        titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => VolunteerRequestPage()),
            ); // Navigate to MainPage
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title of the request with enhanced style
              Text(
                'Title: ${widget.title}',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent
                ),
              ),
              SizedBox(height: 16),

              // Description of the request with proper spacing
              Text(
                'Description: ${widget.description}',
                style: TextStyle(fontSize: 20, color: Colors.black87),
              ),
              SizedBox(height: 20),

              // Category display with icon and style
              Row(
                children: [
                  Icon(Icons.category, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    'Category: ${widget.category}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Urgency display with icon and style
              Row(
                children: [
                  Icon(Icons.priority_high, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Urgency: ${widget.urgency}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Location display with icon and style
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location: ${widget.location}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Get Directions Button with enhanced style
              Center(
                child: ElevatedButton(
                  onPressed: _openGoogleMaps,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                  child: Text('Get Directions'),
                ),
              ),
              SizedBox(height: 30),

              // Volunteer Acceptance Section
              if (!_isVolunteerAccepted) ...[  // If the request hasn't been accepted yet
                Text(
                  'Volunteer Info:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _acceptRequest,
                  child: Text('Accept Request'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ] else ...[
                Text(
                  'You have accepted this request!',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
