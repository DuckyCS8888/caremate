import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'edit_request.dart';

class VolunteerRequestPage extends StatefulWidget {
  @override
  _VolunteerRequestPageState createState() => _VolunteerRequestPageState();
}

class _VolunteerRequestPageState extends State<VolunteerRequestPage> {
  List<DocumentSnapshot> _requests = [];
  bool _loading = true;
  String _filterStatus = 'unaccepted'; // Default filter for unaccepted requests
  int _totalRequests = 0;

  // Volunteer location variables
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _getVolunteerLocation(); // Get volunteer location when the page is loaded
  }

  // Fetch the volunteer's location using Geolocator
  Future<void> _getVolunteerLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } else {
      print('Location permission denied');
    }
  }

  // Method to calculate distance between volunteer and the requestor
  Future<String> _calculateDistance(
    double volunteerLat,
    double volunteerLng,
    double requestLat,
    double requestLng,
  ) async {
    double distanceInMeters = await Geolocator.distanceBetween(
      volunteerLat,
      volunteerLng,
      requestLat,
      requestLng,
    );
    double distanceInKilometers =
        distanceInMeters / 1000; // Convert meters to kilometers

    return distanceInKilometers.toStringAsFixed(2) +
        ' km'; // Return distance with 2 decimal places
  }

  // Fetch all available help requests from Firestore
  Future<void> _fetchRequests() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collectionGroup('requests')
              .where(
                'volunteerAccepted',
                isEqualTo: _filterStatus == 'accepted',
              )
              .orderBy('createdAt')
              .get();

      setState(() {
        _requests = querySnapshot.docs;
        _totalRequests = _requests.length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching requests: $e')));
    }
  }

  // Accept the help request and update Firestore
  Future<void> _acceptRequest(
    String requestId,
    String userName,
    String userId,
  ) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not authenticated')));
        return;
      }

      if (currentUser.uid == userId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You cannot accept your own request')),
        );
        return;
      }

      String userUid = currentUser.uid;
      String volunteerName = '';

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userUid)
              .get();
      volunteerName = userDoc['username'] ?? 'Unknown Volunteer';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('requests')
          .doc(requestId)
          .update({
            'volunteerAccepted': true,
            'volunteerName': volunteerName,
            'volunteerUid': currentUser.uid,
          })
          .then((_) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Request Accepted')));
            _fetchRequests();
          })
          .catchError((e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating request: $e')),
            );
          });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error accepting request: $e')));
    }
  }

  // Cancel the accepted request
  Future<void> _cancelRequest(String requestId, String userId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not authenticated')));
        return;
      }

      DocumentSnapshot requestDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('requests')
              .doc(requestId)
              .get();

      if (requestDoc.exists && requestDoc['volunteerAccepted'] == true) {
        // Check if the current user is the volunteer who accepted the request
        if (requestDoc['volunteerUid'] == currentUser.uid) {
          // Use volunteerUid to check
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('requests')
              .doc(requestId)
              .update({
                'volunteerAccepted': false,
                'volunteerName': null, // Set to null instead of deleting
                'volunteerUid': null, // Set to null instead of deleting
              })
              .then((_) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Request Cancelled')));
                _fetchRequests(); // Refresh the request list after cancellation
              })
              .catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error canceling request: $e')),
                );
              });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can only cancel your own accepted requests'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This request has not been accepted yet')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error canceling request: $e')));
    }
  }

  // Delete the help request if it belongs to the current user
  Future<void> _deleteRequest(String requestId, String userId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not authenticated')));
        return;
      }

      if (currentUser.uid != userId) {
        // Prevent the user from deleting another user's request
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You can only delete your own request')),
        );
        return;
      }

      // Show delete confirmation dialog
      bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Deletion'),
            content: Text('Are you sure you want to delete this request?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(false); // User cancelled the deletion
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(true); // User confirmed the deletion
                },
                child: Text('Delete'),
              ),
            ],
          );
        },
      );

      // Proceed to delete if user confirmed
      if (confirmDelete == true) {
        // Delete the request from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('requests')
            .doc(requestId)
            .delete()
            .then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Request deleted successfully')),
              );
              _fetchRequests(); // Refresh the request list after deletion
            })
            .catchError((e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting request: $e')),
              );
            });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting request: $e')));
    }
  }

  // Show request details in a dialog
  void _showRequestDetails(DocumentSnapshot request) {
    String title = request['title'] ?? 'No title';
    String description = request['description'] ?? 'No description';
    String category = request['category'] ?? 'No category';
    String urgency = request['urgency'] ?? 'N/A';
    double latitude = request['latitude'] ?? 0.0;
    double longitude = request['longitude'] ?? 0.0;
    String userName = request['userName'] ?? 'Unknown User';
    String userId = request['userId'] ?? '';
    String volunteerName = request['volunteerName'] ?? 'No volunteer assigned';
    bool volunteerAccepted = request['volunteerAccepted'] ?? false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.assignment_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person, 'Requested By:', userName),
                _buildInfoRow(Icons.category, 'Category:', category),
                _buildInfoRow(
                  Icons.report_problem_outlined,
                  'Urgency:',
                  urgency,
                ),
                _buildInfoRow(Icons.description, 'Description:', description),
                _buildInfoRow(
                  Icons.location_on,
                  'Location:',
                  'Lat: $latitude, Lng: $longitude',
                ),
                if (volunteerAccepted)
                  _buildInfoRow(Icons.person_add, 'Volunteer:', volunteerName),
                // Show volunteer name if accepted
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.map_outlined,
                    color: Colors.white, // Set icon color to white
                  ),
                  label: Text(
                    'Open in Google Maps',
                    style: TextStyle(
                      color: Colors.white,
                    ), // Set text color to white
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openGoogleMaps(latitude, longitude),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            if (!volunteerAccepted) // Only show accept button if not accepted
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _acceptRequest(
                    request.id,
                    userName,
                    userId,
                  ); // Accept request
                },
                child: Text(
                  'Accept Request',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            if (userId ==
                FirebaseAuth
                    .instance
                    .currentUser
                    ?.uid) // Show delete button if user is the creator
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteRequest(request.id, userId); // Delete own request
                },
                child: Text(
                  'Delete Request',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            if (volunteerAccepted &&
                volunteerName ==
                    FirebaseAuth
                        .instance
                        .currentUser
                        ?.displayName) // Show cancel button if accepted by volunteer
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelRequest(request.id, userId); // Cancel request
                },
                child: Text(
                  'Cancel Request',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
          ],
        );
      },
    );
  }

  // Method to open Google Maps directions
  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.deepOrange),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: '$label ',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help Requests',
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.deepOrange,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Remove shadow for a flat white background
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                dropdownColor: Colors.white,
                icon: Icon(Icons.filter_list, color: Colors.black),
                items: [
                  DropdownMenuItem(
                    value: 'unaccepted',
                    child: Text('Unaccepted'),
                  ),
                  DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value!;
                    _loading = true;
                  });
                  _fetchRequests();
                },
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(
              child: Text(
                'Total: $_totalRequests', // Display total requests count
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body:
          _loading
              ? Center(child: CircularProgressIndicator())
              : _requests.isEmpty
              ? Center(
                child: Text(
                  'No ${_filterStatus} requests available.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  var request = _requests[index];
                  bool isHighUrgency = request['urgency'] == 'High';
                  bool isOwnRequest =
                      request['userId'] ==
                      FirebaseAuth.instance.currentUser?.uid;
                  bool volunteerAccepted =
                      request['volunteerAccepted'] ?? false;

                  // Coordinates of the requestor (user)
                  double requestLat = request['latitude'] ?? 0.0;
                  double requestLng = request['longitude'] ?? 0.0;

                  // Coordinates of the volunteer (current user's location)
                  double volunteerLat = _latitude ?? 0.0; // Volunteer latitude
                  double volunteerLng =
                      _longitude ?? 0.0; // Volunteer longitude

                  return FutureBuilder<String>(
                    future: _calculateDistance(
                      volunteerLat,
                      volunteerLng,
                      requestLat,
                      requestLng,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }

                      String distance = snapshot.data ?? 'Calculating...';

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 8,
                        margin: EdgeInsets.only(bottom: 12),
                        color:
                            isHighUrgency
                                ? Colors.red[50]
                                : volunteerAccepted
                                ? Colors.green[50]
                                : Colors.white,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                volunteerAccepted
                                    ? Colors.green
                                    : Colors.orangeAccent,
                            child: Icon(
                              Icons.volunteer_activism,
                              color: Colors.white,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request['title'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'By: ${request['userName'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOwnRequest)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Chip(
                                    label: Text(
                                      'OWN',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Text('Category: ${request['category']}'),
                              Text('Urgency: ${request['urgency']}'),
                              SizedBox(height: 4),
                              Text('Distance: $distance'), // Display distance
                            ],
                          ),
                          trailing:
                              volunteerAccepted
                                  ? Tooltip(
                                    message:
                                        'Cancel Request', // The text that will appear when the user long presses the icon
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _cancelRequest(
                                            request.id,
                                            request['userId'],
                                          ),
                                    ),
                                  )
                                  : isOwnRequest // Show Delete and Edit buttons if it's the user's own request
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Edit Button
                                      Tooltip(
                                        message:
                                            'Edit Request', // Tooltip text that appears when the user long-presses the icon
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () {
                                            // Navigate to the EditRequestPage
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => EditRequestPage(
                                                      requestId: request.id,
                                                      currentTitle:
                                                          request['title'],
                                                      currentDescription:
                                                          request['description'],
                                                      currentCategory:
                                                          request['category'],
                                                      currentUrgency:
                                                          request['urgency'],
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      // Delete Button
                                      Tooltip(
                                        message:
                                            'Delete Request', // Tooltip text when the user long-presses the icon
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            // Trigger delete with confirmation
                                            _deleteRequest(
                                              request.id,
                                              request['userId'],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                  : Icon(
                                    Icons.info_outline,
                                    color: Colors.blueGrey,
                                  ),
                          onTap: () => _showRequestDetails(request),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
