import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projects/profile/profilepage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert'; // For base64 encoding // ProfilePage to navigate after save

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}
//testing
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

  // Function to pick the image
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
          'profilePic': profilePicBase64.isEmpty ? user.photoURL : profilePicBase64, // Save base64 or default photo URL
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Updated Successfully!')),
        );

        // Navigate back to ProfilePage and refresh the data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()), // Navigate back to ProfilePage
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
                        : AssetImage('assets/images/default_profile.png') as ImageProvider,
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
