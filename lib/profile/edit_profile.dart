import 'dart:convert'; // For base64 encoding/decoding
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projects/home.dart'; // MainPage where bottom navigation is defined
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _jobController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  TextEditingController _contactController = TextEditingController();

  File? _profileImage;  // Variable to store the profile picture
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImage;
  bool _isImagePicked = false;

  // To store the previous profile picture data (base64)
  String _previousProfilePicBase64 = '';

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data when the page is initialized
  }

  // Function to load current user data from Firestore
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch user data from Firestore
        DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        DocumentSnapshot snapshot = await userDocRef.get();

        if (snapshot.exists) {
          var data = snapshot.data() as Map<String, dynamic>;

          setState(() {
            // Pre-populate the form fields with the current data
            _usernameController.text = data['username'] ?? '';
            _jobController.text = data['job'] ?? '';
            _bioController.text = data['bio'] ?? '';
            _contactController.text = data['contact'] ?? '';
            _previousProfilePicBase64 = data['profilePic'] ?? ''; // Store the profile picture base64 string

            // Decode the profile picture if available
            if (_previousProfilePicBase64.isNotEmpty) {
              _selectedImage = base64Decode(_previousProfilePicBase64);
              _isImagePicked = true;
            }
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  // Function to pick the image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = imageBytes;
        _isImagePicked = true;
      });
    }
  }

  // Convert image to base64 string
  String _convertImageToBase64(Uint8List imageFile) {
    return base64Encode(imageFile);
  }

  // Save Profile to Firebase
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (_usernameController.text.isEmpty ||
          _jobController.text.isEmpty ||
          _bioController.text.isEmpty ||
          _contactController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }

      try {
        String profilePicBase64 = '';

        // If profile image is selected, convert it to base64
        if (_selectedImage != null) {
          profilePicBase64 = _convertImageToBase64(_selectedImage!);
        }

        // Save profile data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': _usernameController.text.trim(),
          'job': _jobController.text.trim(),
          'bio': _bioController.text.trim(),
          'contact': _contactController.text.trim(),
          'profilePic': profilePicBase64.isEmpty ? _previousProfilePicBase64 : profilePicBase64, // Use previous profile picture if not updated
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Updated Successfully!')),
        );

        // Navigate back to MainPage and set selectedIndex to 4 (ProfilePage)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage(selectedIndex: 4)), // Pass selectedIndex 4 for ProfilePage
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,  // When tapped, allow the user to pick an image
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _isImagePicked
                        ? MemoryImage(_selectedImage!)
                        : (_previousProfilePicBase64.isNotEmpty
                        ? MemoryImage(base64Decode(_previousProfilePicBase64))
                        : AssetImage('assets/images/default_profile.png')) as ImageProvider,
                  ),
                ),
                const SizedBox(height: 20),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Job Field
                TextFormField(
                  controller: _jobController,
                  decoration: InputDecoration(labelText: 'Job'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your job';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Bio Field
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(labelText: 'Bio'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your bio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Contact Number Field
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(labelText: 'Contact Number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _saveProfile();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black, backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Save Changes"),
                    ),
                    ElevatedButton(
                      onPressed: () {},  // No function for this button
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black, backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Log Out"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
