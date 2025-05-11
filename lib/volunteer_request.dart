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
  String _filterStatus = 'unaccepted'; // Default filter for unaccepted requests

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  // Fetch all available help requests from Firestore
  Future<void> _fetchRequests() async {
    try {
      // Querying across all requests subcollections based on the selected filter
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('requests') // Fetch all requests across all users
          .where('volunteerAccepted', isEqualTo: _filterStatus ==
          'accepted') // Filter based on the selected status
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching requests: $e')));
    }
  }

  // Accept the help request and update Firestore
  Future<void> _acceptRequest(String requestId, String userName, String userId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not authenticated')));
        return;
      }

      if (currentUser.uid == userId) {
        // Prevent the user from accepting their own request
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You cannot accept your own request')));
        return;
      }

      String userUid = currentUser.uid;
      String volunteerName = '';

      // Fetch volunteer name from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .get();
      volunteerName = userDoc['username'] ?? 'Unknown Volunteer';

      // Update Firestore to mark the request as accepted
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('requests')
          .doc(requestId)
          .update({
        'volunteerAccepted': true,
        'volunteerName': volunteerName,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request Accepted')));
        _fetchRequests(); // Refresh the request list after accepting
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating request: $e')));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error accepting request: $e')));
    }
  }

  Future<void> _deleteRequest(String requestId, String userId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not authenticated')));
        return;
      }

      if (currentUser.uid != userId) {
        // Prevent the user from deleting other user's request
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can only delete your own request')));
        return;
      }

      // Delete the request from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('requests')
          .doc(requestId)
          .delete()
          .then((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request deleted successfully')));
        _fetchRequests(); // Refresh the request list after deletion
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting request: $e')));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting request: $e')));
    }
  }

  Future<void> _cancelRequest(String requestId, String userId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not authenticated')));
        return;
      }

      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('requests')
          .doc(requestId)
          .get();

      if (requestDoc.exists && requestDoc['volunteerAccepted'] == true) {
        if (requestDoc['volunteerName'] == currentUser.displayName) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('requests')
              .doc(requestId)
              .update({
            'volunteerAccepted': false,
            'volunteerName': FieldValue.delete(),
          }).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request Cancelled')));
            _fetchRequests(); // Refresh the request list after cancellation
          }).catchError((e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error canceling request: $e')));
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can only cancel your own accepted requests')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This request has not been accepted yet')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error canceling request: $e')));
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                _buildInfoRow(Icons.report_problem_outlined, 'Urgency:', urgency),
                _buildInfoRow(Icons.description, 'Description:', description),
                _buildInfoRow(Icons.location_on, 'Location:', 'Lat: $latitude, Lng: $longitude'),
                if (volunteerAccepted)
                  _buildInfoRow(Icons.person_add, 'Volunteer:', volunteerName), // Show volunteer name if accepted
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.map_outlined),
                  label: Text('Open in Google Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  _acceptRequest(request.id, userName, userId); // Accept request
                },
                child: Text('Accept Request'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            if (userId == FirebaseAuth.instance.currentUser?.uid) // Show delete button if user is the creator
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteRequest(request.id, userId); // Delete own request
                },
                child: Text('Delete Request'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            if (volunteerAccepted && volunteerName == FirebaseAuth.instance.currentUser?.displayName) // Show cancel button if accepted by volunteer
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelRequest(request.id, userId); // Cancel request
                },
                child: Text('Cancel Request'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
          ],
        );
      },
    );
  }

  // Method to open Google Maps directions
  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
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
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help Requests'),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                dropdownColor: Colors.white,
                icon: Icon(Icons.filter_list, color: Colors.white),
                items: [
                  DropdownMenuItem(
                      value: 'unaccepted', child: Text('Unaccepted')),
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
          )
        ],
      ),
      body: _loading
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
          // Highlight High urgency requests
          bool isHighUrgency = request['urgency'] == 'High';

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 8, // Shadow for depth
            margin: EdgeInsets.only(bottom: 12),
            color: isHighUrgency ? Colors.red[50] : Colors.white, // Color for high urgency
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: _filterStatus == 'accepted'
                    ? Colors.green
                    : Colors.orangeAccent,
                child: Icon(Icons.volunteer_activism, color: Colors.white),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request['title'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'By: ${request['userName'] ?? 'Unknown'}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text('Category: ${request['category']}'),
                  Text('Urgency: ${request['urgency']}'),
                ],
              ),
              trailing: Icon(Icons.info_outline, color: Colors.blueGrey),
              onTap: () => _showRequestDetails(request),
            ),
          );
        },
      )
    );
  }
}
