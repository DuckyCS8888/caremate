import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class VolunteerRequestPage extends StatefulWidget {
  @override
  _VolunteerRequestPageState createState() => _VolunteerRequestPageState();
}

class _VolunteerRequestPageState extends State<VolunteerRequestPage> {
  List<DocumentSnapshot> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  // Fetch all available help requests from Firestore
  Future<void> _fetchRequests() async {
    try {
      // Querying across all requests subcollections
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('requests')  // Fetch all requests across all users
          .where('volunteerAccepted', isEqualTo: false)  // Only unaccepted requests
          .orderBy('createdAt')
          .get();
      print("Total Requests: ${querySnapshot.docs.length}");
      if (querySnapshot.docs.isNotEmpty) {
        print("Request Data: ${querySnapshot.docs[0].data()}");
      }
      setState(() {
        _requests = querySnapshot.docs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching requests: $e')));
    }
  }

// Accept the help request and update Firestore
  Future<void> _acceptRequest(String requestId, String userName, String userId) async {
    try {
      // Get the current authenticated user
      User? currentUser = FirebaseAuth.instance.currentUser;
      print("Current User: ${currentUser?.uid}");

      // Check if user is authenticated
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not authenticated')));
        return;
      }

      String userUid = currentUser.uid; // Get the Firebase Authentication UID (auto-generated)
      String volunteerName = '';

      try {
        // Fetch userName from Firestore (from the 'users' collection)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userUid)
            .get();

        // If userName exists, use it; otherwise, default to 'Unknown Volunteer'
        volunteerName = userDoc['username'] ?? 'Unknown Volunteer';
      } catch (e) {
        print("Error fetching user data: $e");
      }

      // Update Firestore to mark the request as accepted and associate the volunteer
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId) // Use the unique userId to find the correct user
          .collection('requests')
          .doc(requestId)
          .update({
        'volunteerAccepted': true,
        'volunteerName': volunteerName, // Use fetched volunteerName
      })
          .then((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request Accepted')));
        _fetchRequests(); // Refresh the request list after accepting
      })
          .catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating request: $e')));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error accepting request: $e')));
    }
  }

  // Show request details in a dialog
  void _showRequestDetails(DocumentSnapshot request) {
    // Make sure you are extracting the correct fields from the request
    String title = request['title'] ?? 'No title';  // Default value in case key doesn't exist
    String description = request['description'] ?? 'No description available';
    String category = request['category'] ?? 'No category';
    String urgency = request['urgency'] ?? 'No urgency';
    double latitude = request['latitude'] ?? 0.0;
    double longitude = request['longitude'] ?? 0.0;
    String userName = request['userName'] ?? 'Unknown User';  // Ensure 'userName' exists
    String userId = request['userId'] ?? '';  // Ensure 'userId' exists

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(  // To allow scrolling if content overflows
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Description: $description'),
                Text('Category: $category'),
                Text('Urgency: $urgency'),
                SizedBox(height: 10),
                Text('Location: Latitude: $latitude, Longitude: $longitude'),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _openGoogleMaps(latitude, longitude),
                  child: Text('Open Directions in Google Maps'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),  // Close the dialog
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog before accepting
                _acceptRequest(request.id, userName, userId); // Pass both userName and userId
              },
              child: Text('Accept Request'),
            ),
          ],
        );
      },
    );
  }

  // Method to open Google Maps directions
  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    final Uri uri = Uri.parse(url); // Convert string URL into Uri

    // Check if the URL can be launched
    if (await canLaunchUrl(uri)) {
      // Launch the URL in the default browser or Google Maps app
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Help Requests'),
        backgroundColor: Colors.orange,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          var request = _requests[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(request['title']),
              subtitle: Text(request['category']),
              trailing: IconButton(
                icon: Icon(Icons.info),
                onPressed: () => _showRequestDetails(request),
              ),
            ),
          );
        },
      ),
    );
  }
}
