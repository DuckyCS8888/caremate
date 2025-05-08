import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'request_detail.dart';

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
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
        titleTextStyle: TextStyle(color: Colors.white),
        elevation: 4.0,  // Slight shadow for elevation
      ),
      body: _volunteerLatitude == null || _volunteerLongitude == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final distance = _calculateDistance(
                _volunteerLatitude!,
                _volunteerLongitude!,
                request['latitude'],
                request['longitude'],
              );

              // Determine background color based on urgency
              Color urgencyColor = request['urgency'] == 'High' ? Colors.red[100]! : Colors.white;
              return Card(
                elevation: 3.0,
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: ListTile(
                  tileColor: urgencyColor, // Set background color based on urgency
                  contentPadding: EdgeInsets.all(16.0),
                  title: Text(
                    request['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      decoration: TextDecoration.underline, // This applies the underline
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${distance.toStringAsFixed(2)} km away', style: TextStyle(fontSize: 16, color: Colors.black87)),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('Category: ${request['category']}', style: TextStyle(fontSize: 16, color: Colors.black87)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.priority_high, size: 16, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Urgency: ${request['urgency']}', style: TextStyle(fontSize: 16, color: Colors.black87)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Location: ${request['location']}', style: TextStyle(fontSize: 16, color: Colors.black87)),
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
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
