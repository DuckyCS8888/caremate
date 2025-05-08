import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestDetailPage extends StatelessWidget {
  final String title;
  final String description;
  final String category;  // New field for category
  final String urgency;   // New field for urgency
  final num latitude;
  final num longitude;
  final String location;  // New field for location (manual or auto-filled)

  RequestDetailPage({
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    required this.latitude,
    required this.longitude,
    required this.location,
  });

  // Method to open Google Maps directions
  Future<void> _openGoogleMaps() async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Details'),
        backgroundColor: Colors.orange,  // Consistent app bar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(  // Allow scrolling for smaller screens
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title of the request with enhanced style
              Text(
                'Title: $title',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent
                ),
              ),
              SizedBox(height: 16),

              // Description of the request with proper spacing
              Text(
                'Description: $description',
                style: TextStyle(fontSize: 20, color: Colors.black87),
              ),
              SizedBox(height: 20),

              // Category display with icon and style
              Row(
                children: [
                  Icon(Icons.category, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    'Category: $category',
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
                    'Urgency: $urgency',
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
                      'Location: $location',
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
            ],
          ),
        ),
      ),
    );
  }
}
