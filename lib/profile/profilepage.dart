import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart'; // Edit profile page

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Firestore Collection reference to fetch data
  final CollectionReference fetchData = FirebaseFirestore.instance.collection("users");

  String _username = '';
  String _job = '';
  String _bio = '';
  String _contact = '';
  String _profilePicUrl = 'https://via.placeholder.com/150'; // Default placeholder image

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load data when the page is loaded
  }

  
  // Function to load user data from Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch user data from Firestore using the current user's UID
        DocumentSnapshot snapshot = await fetchData.doc(user.uid).get();

        if (snapshot.exists) {
          var data = snapshot.data() as Map<String, dynamic>;

          setState(() {
            _username = data['username'] ?? 'No username';
            _job = data['job'] ?? 'No job';
            _bio = data['bio'] ?? 'No bio';
            _contact = data['contact'] ?? 'No contact';
            _profilePicUrl = data['profilePic'] ?? 'https://via.placeholder.com/150';  // Default if no profile pic
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Page", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_profilePicUrl),  // Use the fetched profile picture URL
              ),
              SizedBox(height: 10),

              // Name and Role
              Text(
                _username,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                _job,
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),

              // Bio
              Text(
                _bio,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Contact Info
              Text(
                _contact,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to EditProfilePage and wait for results
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfilePage()), // Navigate to EditProfilePage
                      ).then((_) {
                        // Force refresh the data when returning from EditProfilePage
                        _loadUserData(); // Reload the data when coming back
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Edit Profile'),
                  ),
                  ElevatedButton(
                    onPressed: () {},  // No function for this button
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Create Posts'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ProfilePage(),  // ProfilePage as the home page
  ));
}
