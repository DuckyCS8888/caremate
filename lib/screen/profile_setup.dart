import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../home.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  _ProfileSetupState createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  Uint8List? _selectedImage;
  bool _isImagePicked = false;

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
    if (user != null) {
      if (!_formKey.currentState!.validate() || !_isImagePicked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill all fields correctly and pick a profile picture',
            ),
          ),
        );
        return;
      }

      try {
        String base64Image = base64Encode(_selectedImage!);

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': _usernameController.text.trim(),
          'email': user.email,
          'contact': _contactController.text.trim(),
          'job': _jobController.text.trim(),
          'bio': _bioController.text.trim(),
          'profilePic': base64Image,
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile Saved Successfully!')));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Complete Your Profile Setup ",
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight:
            FontWeight.w700, // Replace with your desired font family
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        _isImagePicked
                            ? MemoryImage(_selectedImage!)
                            : AssetImage("assets/images/defaultpfp.png")
                                as ImageProvider,
                  ),
                ),
                const SizedBox(height: 20),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    hintText: 'Enter your username',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    } else if (value.length < 3) {
                      return 'Minimum 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Contact
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    hintText: 'Enter your contact number',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Contact number is required';
                    } else if (!RegExp(r'^\d{10,11}$').hasMatch(value)) {
                      return 'Enter valid phone number (10–11 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Job
                TextFormField(
                  controller: _jobController,
                  decoration: InputDecoration(
                      labelText: 'Job',
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    hintText: 'Enter your Job',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Job is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Bio
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                      labelText: 'Bio',
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    hintText: 'Enter your Bio',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bio is required';
                    } else if (value.length < 10) {
                      return 'Bio must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(
                      MediaQuery.of(context).size.width * 0.7,
                      50,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(
                      'Save Profile',
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
