import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile.dart'; // Edit profile page
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Firestore Collection reference to fetch data
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = '';
  String _job = '';
  String _bio = '';
  String _profilePicUrl = ''; // Profile picture URL as base64 string
  Uint8List? _profilePic; // To hold decoded image data

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
        // Reference to the user's document in Firestore
        DocumentReference userDocRef = _firestore.collection("users").doc(user.uid);

        // Fetch user data from Firestore using the current user's UID
        DocumentSnapshot snapshot = await userDocRef.get();

        if (snapshot.exists) {
          var data = snapshot.data() as Map<String, dynamic>;

          setState(() {
            _username = data['username'] ?? 'No username';
            _job = data['job'] ?? 'No job';
            _bio = data['bio'] ?? 'No bio';
            _profilePicUrl = data['profilePic'] ?? ''; // Base64 string
            _profilePic = _profilePicUrl.isNotEmpty ? base64Decode(_profilePicUrl) : null; // Decode the base64 string
          });
        } else {
          print('No data found for user ${user.uid}');
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    } else {
      print('No user logged in');
    }
  }

  // Function to display the full profile picture
  void _showFullProfilePic(BuildContext context) {
    if (_profilePic != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Image.memory(
                    _profilePic!,
                    fit: BoxFit.cover,
                    height: MediaQuery.of(context).size.height * 0.7,
                    width: MediaQuery.of(context).size.width * 0.7,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "CareMate",
          style: GoogleFonts.comicNeue(
            fontSize: 35,
            fontWeight: FontWeight.w900, // Replace with your desired font family
            color: Colors.deepOrange,
          ),
        ),
        backgroundColor: Colors.white,
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
              // Profile Picture - wrapped with GestureDetector
              GestureDetector(
                onTap: () => _showFullProfilePic(context), // Show full profile image on tap
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePic != null
                      ? MemoryImage(_profilePic!) // Display image if it's loaded
                      : NetworkImage('https://via.placeholder.com/150') as ImageProvider, // Default image if no profile pic
                ),
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
