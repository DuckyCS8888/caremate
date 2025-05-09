import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'home.dart';
import 'dart:typed_data';

import 'package:projects/home.dart';
import 'package:projects/main.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  _ProfileSetupState createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  Uint8List? _selectedImage;
  bool _isImagePicked = false;

  // Pick the profile image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = imageBytes;
        _isImagePicked = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    print('Test1');
    if (user != null) {
      print('Test2');
      if (_usernameController.text.isEmpty ||
          _contactController.text.isEmpty ||
          !_isImagePicked) {
        print('Test3');
        // Show error if any field is empty
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields and pick a profile picture')),
        );
        return;
      }

      try {
        print('Test4');
        // Upload the profile picture to Firebase Storage if picked
        String profilePicUrl = '';
        if (_isImagePicked && _selectedImage != null) {
          print('Test5');
          // Upload to Firebase Storage
          final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}.jpg');
          //-->await storageRef.putData(_selectedImage!);
          //-->profilePicUrl = await storageRef.getDownloadURL(); // Get the URL of the uploaded image
        }
        print('Test6');
        // Save profile data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'username': _usernameController.text.trim(),
          'email': user.email, // Email from Firebase Authentication
          'contact': _contactController.text.trim(),
          'profilePic': profilePicUrl, // Store profile picture URL
        });

        print('Success');
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Saved Successfully!')),
        );

        // Navigate to main UI (replace with your main screen route)
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } catch (e) {
        // Show specific error message for troubleshooting
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Complete Your Profile'), backgroundColor: Colors.orange),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Picture Picker
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _isImagePicked
                      ? MemoryImage(_selectedImage!) // Show selected image
                      : AssetImage('assets/images/default_profile.png') as ImageProvider,
                ),
              ),
              const SizedBox(height: 20),

              // Username TextField
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username',
                ),
              ),
              const SizedBox(height: 20),

              // Contact Number TextField
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  hintText: 'Enter your contact number',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // Save Profile Button
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(MediaQuery.of(context).size.width * 0.7, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.orange,
                ),
                child: Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
