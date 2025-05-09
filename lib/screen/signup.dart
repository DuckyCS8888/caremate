import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:projects/screen/login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  // Image picker
  Uint8List? _selectedImage; // To store the selected images
  bool _isImagePicked = false; // To check if an images is picked
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickImage() async {
    final picker = ImagePicker(); // Make sure to instantiate ImagePicker
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = imageBytes;
        _isImagePicked = true;
      });
    }
  }

  // Function to show the Date Picker for Date of Birth
  Future<void> _selectDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1900), // Minimum year for date selection
      lastDate: currentDate, // Maximum year for date selection
    );

    if (pickedDate != null && pickedDate != currentDate) {
      setState(() {
        _dobController.text =
            "${pickedDate.toLocal()}".split(
              ' ',
            )[0]; // Format date as yyyy-MM-dd
      });
    }
  }

  // Function to handle the sign-up process
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (!_isImagePicked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a profile picture.')),
        );
        return;
      }

      try {
        // Register the user with Firebase Authentication
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        print('created');
        final user = userCredential.user;
        if (user != null) {
          // Upload profile picture to Firebase Storage if picked
          String profilePicUrl = '';
          if (_isImagePicked && _selectedImage != null) {
            final storageRef = _storage.ref().child('profile_pictures/${user.uid}.jpg');
            await storageRef.putData(_selectedImage!);
            profilePicUrl = await storageRef.getDownloadURL(); // Get the URL of the uploaded image
          }

          // Save the user information in Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'dob': _dobController.text.trim(),
            'contact': _contactController.text.trim(),
            'profilePic': profilePicUrl, // URL of the profile picture
          });

          print('Success');

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign Up Successful!')),
          );

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase authentication errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication Error: ${e.message}')),
        );
      } catch (e) {
        // Handle other errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Beige color
      appBar: AppBar(title: Text('Sign Up'), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Picture Placeholder (Only show default until user picks an image)
                GestureDetector(
                  onTap: _pickImage, // Pick image on tap
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _isImagePicked
                        ? MemoryImage(_selectedImage!) // Show picked image
                        : AssetImage('assets/images/default_profile.png'), // Default image if none selected
                  ),
                ),
                const SizedBox(height: 20),

                // Username TextField
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email TextField
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password TextField
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm Password TextField
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    hintText: 'Enter your password again',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Date of Birth (DOB) TextField with Date Picker icon
                GestureDetector(
                  onTap: () => _selectDate(context), // Show date picker on tap
                  child: AbsorbPointer(
                    // Makes TextField non-editable (user can only pick date)
                    child: TextFormField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        suffixIcon: Icon(
                          Icons.calendar_today,
                        ), // Calendar icon on the right side
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your date of birth';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Contact Number TextField with validator for 10-11 digits
                TextFormField(
                  controller: _contactController,
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
                  keyboardType: TextInputType.phone,  // Ensure numeric input
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact number';
                    }

                    // Remove any non-digit characters (e.g., spaces, dashes)
                    String cleanedValue = value.replaceAll(RegExp(r'\D'), '');

                    // Validate phone number length for Malaysia (10-11 digits)
                    if (cleanedValue.length < 10 || cleanedValue.length > 11) {
                      return 'Please enter a valid phone number (10-11 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),  // Space between fields

                // Sign Up Button
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(
                      MediaQuery.of(context).size.width * 0.7, 50,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(
                    'Sign Up',
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
