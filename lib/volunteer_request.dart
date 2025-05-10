import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projects/request_detail.dart';

class VolunteerRequestPage extends StatefulWidget {
  @override
  _VolunteerRequestPageState createState() => _VolunteerRequestPageState();
}

class _VolunteerRequestPageState extends State<VolunteerRequestPage> {
  double? _volunteerLatitude, _volunteerLongitude;

  @override
  void initState() {
    super.initState();
    _getVolunteerLocation();
  }

  // Get volunteer's current location
  Future<void> _getVolunteerLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _volunteerLatitude = position.latitude;
      _volunteerLongitude = position.longitude;
    });
  }

  // Calculate distance between volunteer and request location (in km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // distance in km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Requests'),
        backgroundColor: Colors.red,
        titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        elevation: 5.0, // Slight shadow for elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _volunteerLatitude == null || _volunteerLongitude == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('requests')  // This works for all 'requests' subcollections
            .where('volunteerAccepted', isEqualTo: false) // Only fetch unaccepted requests
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(child: Text('Something went wrong'));
          }

          final requests = snapshot.data!.docs;
          print('Number of requests: ${requests.length}'); // Debugging line

          if (requests.isEmpty) {
            return Center(child: Text("No requests available"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final latitude = request['latitude'];
              final longitude = request['longitude'];

              if (latitude == null || longitude == null) {
                print('Missing location data for request ID: ${request.id}');
                return ListTile(title: Text('Missing location data'));
              }

              final distance = _calculateDistance(
                _volunteerLatitude!,
                _volunteerLongitude!,
                latitude,
                longitude,
              );

              Color urgencyColor = request['urgency'] == 'High' ? Colors.red[100]! : Colors.white;

              return Card(
                elevation: 6.0,
                margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                shadowColor: Colors.black.withOpacity(0.2),
                child: ListTile(
                  tileColor: urgencyColor,
                  contentPadding: EdgeInsets.all(16.0),
                  title: Text(
                    request['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${distance.toStringAsFixed(2)} km away',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Category: ${request['category']}',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.priority_high, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Urgency: ${request['urgency']}',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Location: ${request['location']}',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestDetailPage(
                          title: request['title'],
                          description: request['description'],
                          category: request['category'],
                          urgency: request['urgency'],
                          latitude: request['latitude'],
                          longitude: request['longitude'],
                          location: request['location'],
                          requestId: request.id,
                        ),
                      ),
                    );
                  },
                  trailing: ElevatedButton(
                    onPressed: () {
                      _acceptRequest(request.id, request.reference.parent.id);
                    },
                    child: Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      )

    );
  }

  // Function to accept the request
  Future<void> _acceptRequest(String requestId, String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to accept a request')),
      );
      return;
    }

    String volunteerName = await _getUsername(
      currentUser.uid,
    ); // Retrieve username
    try {
      // Update the request document using requestId to mark it as accepted and add volunteer details (email as contact)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId) // User document ID
          .collection('requests')
          .doc(requestId) // Use the requestId to update the request
          .update({
        'volunteerName': volunteerName, // Set the volunteer's name to their username
        'volunteerAccepted': true, // Mark the request as accepted
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request accepted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error accepting request: $e')));
    }
  }

  // Helper method to retrieve the username from Firestore
  Future<String> _getUsername(String userId) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

      return userDoc['username'] ?? 'Unknown'; // Return 'Unknown' if the username doesn't exist
    } catch (e) {
      return 'Unknown';
    }
  }
}
