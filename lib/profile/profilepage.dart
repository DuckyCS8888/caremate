import 'dart:convert'; // For base64 encoding/decoding
import 'dart:typed_data'; // For Uint8List
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projects/screen/login.dart';
import 'package:projects/screen/welcome_screen.dart';
import 'edit_profile.dart'; // Edit profile page

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
  int _postCount = 0;  // For storing total post count
  List<DocumentSnapshot> _userPosts = [];  // To store user's posts

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load data when the page is loaded
    _loadUserPosts(); // Load posts when the page is loaded
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
    }
  }

  // Function to load user posts from Firestore
  Future<void> _loadUserPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch user's posts from Firestore
        QuerySnapshot postSnapshot = await _firestore.collection('users').doc(user.uid).collection('posts').get();

        setState(() {
          _userPosts = postSnapshot.docs;
          _postCount = _userPosts.length;
        });
      } catch (e) {
        print('Error loading user posts: $e');
      }
    }
  }

  // Function to delete the post
  void _deletePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).collection('posts').doc(postId).delete();
        // Reload the posts after deletion
        _loadUserPosts();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted successfully')));
      } catch (e) {
        print('Error deleting post: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting post')));
      }
    }
  }

  // Function to show the delete confirmation dialog
  void _showDeleteConfirmationDialog(String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Post?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deletePost(postId); // Delete the post
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }



  // Function to display the full profile picture with a blurred background
  void _showFullProfilePic(BuildContext context) {
    if (_profilePic != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent, // Transparent background for dialog
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // Close the dialog when tapped
              },
              child: Stack(
                children: [
                  // BackdropFilter to blur the background
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Set the blur intensity
                      child: Container(
                        color: Colors.black.withOpacity(0), // Keep the background transparent with slight opacity
                      ),
                    ),
                  ),
                  // Profile image in circle
                  Center(
                    child: CircleAvatar(
                      radius: 120, // Smaller circle size for the profile picture
                      backgroundImage: MemoryImage(_profilePic!),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  // Function to log out with confirmation dialog
  void _logOut() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Are you sure you want to log out of your account?',
            style: GoogleFonts.comicNeue(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Perform log out
                await FirebaseAuth.instance.signOut();

                // Navigate to the WelcomeScreen after logging out
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Log out',
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Profile Page",
          style: GoogleFonts.comicNeue(
            fontSize: 25,
            fontWeight: FontWeight.w900,
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
                onTap: () => _showFullProfilePic(context),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePic != null
                      ? MemoryImage(_profilePic!)
                      : NetworkImage('https://via.placeholder.com/150') as ImageProvider,
                ),
              ),
              SizedBox(height: 10),

              // Name and Role
              Text(
                _username,
                style: GoogleFonts.comicNeue(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                _job,
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),

              // Bio
              Text(
                _bio,
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Total post count
              Text(
                '$_postCount',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.w900, // Bold weight for the count
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Posts',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfilePage()),
                      ).then((_) {
                        _loadUserData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Edit Profile',
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _logOut,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Log Out',
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              /// Display posts in GridView
              SizedBox(height: 20),  // Add spacing between buttons and post images
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,  // Increased spacing between columns
                  mainAxisSpacing: 12,   // Increased spacing between rows
                ),
                itemCount: _userPosts.length,
                itemBuilder: (context, index) {
                  String imageUrl = _userPosts[index]['image']; // Assuming the post has an 'image' field

                  return Stack(
                    children: [
                      // The image is displayed here, but no navigation happens
                      GestureDetector(
                        child: Image.memory(
                          base64Decode(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // Show delete confirmation dialog
                            _showDeleteConfirmationDialog(_userPosts[index].id);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ProfilePage(),
  ));
}
