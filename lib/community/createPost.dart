import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // For base64 encoding
import 'dart:typed_data'; // For Uint8List
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  TextEditingController _contentController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  Uint8List? _imageBytes; // Store the post image as Uint8List
  String _selectedLocation = 'Select Location'; // Default location
  String _selectedCategory = 'Select Category'; // Default category
  bool _isLocationValid = true; // Validity of the location field
  bool _isCategoryValid = true; // Validity of the category field

  // Maximum allowed image size for uploading to Firestore (e.g., 750KB)
  final int maxImageSizeInBytes = 750 * 1024;

  // Function to pick and compress the image
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      try {
        // Read the image file as bytes
        final imageBytes = await pickedFile.readAsBytes();

        // Compress the image
        final compressedImage = await FlutterImageCompress.compressWithList(
          imageBytes,
          minHeight: 800,
          minWidth: 800,
          quality: 85,
        );

        // Check if the compressed image size exceeds the maximum allowed size
        if (compressedImage.lengthInBytes > maxImageSizeInBytes) {
          final sizeInKB = (compressedImage.lengthInBytes / 1024)
              .toStringAsFixed(1);
          final limitInKB = (maxImageSizeInBytes / 1024).toStringAsFixed(0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image too large ($sizeInKB KB). Max ~${limitInKB}KB allowed.',
              ),
            ),
          );
          return; // Exit if image is too large
        }

        // Set the compressed image in the state
        setState(() {
          _imageBytes = compressedImage;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking/compressing image: ${e.toString()}'),
          ),
        );
        print("Image picking/compression error: $e");
      }
    }
  }

  Future<String?> _getUsername() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          return userDoc['username']; // Assuming the username is stored under the field 'username'
        }
      } catch (e) {
        print("Error fetching username: $e");
        return null;
      }
    }
    return null;
  }

  Future<String?> _getProfilePicBase64() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          return userDoc['profilePic']; // Assuming the base64 profile image is stored under 'profilePic'
        }
      } catch (e) {
        print("Error fetching profile picture: $e");
        return null;
      }
    }
    return null;
  }

  Future<void> _createPost() async {
    // Validate that all fields are filled correctly
    if (_contentController.text.isEmpty ||
        _imageBytes == null ||
        _selectedLocation == 'Select Location' ||
        _selectedCategory == 'Select Category') {
      setState(() {
        _isLocationValid = _selectedLocation != 'Select Location';
        _isCategoryValid = _selectedCategory != 'Select Category';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all fields, including selecting a location and category.',
          ),
        ),
      );
      return;
    }

    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No user is logged in')));
      return;
    }

    // Get the username and profile picture (base64) from Firestore
    String? username = await _getUsername();
    String? profilePicBase64 = await _getProfilePicBase64();

    if (username == null || profilePicBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username or profile picture not found')),
      );
      return;
    }

    // Convert the post image to base64 before storing in Firestore
    String base64Image = base64Encode(_imageBytes!);

    // Get the current timestamp
    Timestamp timestamp = Timestamp.now();

    // Add the post data to Firestore
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('posts')
          .add({
            'content': _contentController.text,
            'image': base64Image, // Store the post image in base64
            'timestamp': timestamp,
            'likes': [],
            'location': _selectedLocation,
            'category': _selectedCategory, // Store the selected category
            'userID': user.uid, // Store the user's UID
            'username': username, // Store the username
            'profilePic':
                profilePicBase64, // Store the user's profile picture in base64
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Post created successfully')));
      _contentController.clear();
      _locationController.clear();
      setState(() {
        _imageBytes = null;
        _selectedLocation = 'Select Location';
        _selectedCategory = 'Select Category'; // Reset category
        _isLocationValid = true;
        _isCategoryValid = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating post')));
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, // Change the color of the back arrow here
        ),
        title: Text(
          "Create Post",
          style: GoogleFonts.comicNeue(
            fontSize: 30,
            fontWeight:
                FontWeight.w700, // Replace with your desired font family
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Text input for post content (italic, black text)
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'What\'s on your mind?',
                  labelStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black, // Black color for the label
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2), // Default border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2), // Black color and bold width when focused
                ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Location Dropdown (using Google Fonts)
              Row(
                children: [
                  Text(
                    'Location:',
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                    fontSize: 20),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedLocation,
                    items:
                        <String>[
                          'Select Location',
                          'Johor',
                          'Kedah',
                          'Kelantan',
                          'Melaka',
                          'Negeri Sembilan',
                          'Pahang',
                          'Perak',
                          'Perlis',
                          'Penang',
                          'Sabah',
                          'Sarawak',
                          'Selangor',
                          'Terengganu',
                          'Labuan',
                          'Kuala Lumpur',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Colors.black, // Black font color
                                fontWeight: FontWeight.bold, // Bold font
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLocation = newValue!;
                        _isLocationValid =
                            _selectedLocation !=
                            'Select Location'; // Validate location
                      });
                    },
                  ),
                ],
              ),

              // Show validation error if location is not selected
              if (!_isLocationValid)
                Text(
                  'Please select a valid location',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              SizedBox(height: 16),

              // Category Dropdown (same styling as Location)
              Row(
                children: [
                  Text(
                    'Category:',
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    items:
                        <String>[
                          'Select Category',
                          'Food',
                          'Fund',
                          'Shelter',
                          'Health',
                          'Education',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                color: Colors.black, // Black font color
                                fontWeight: FontWeight.bold, // Bold font
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                        _isCategoryValid =
                            _selectedCategory !=
                            'Select Category'; // Validate category
                      });
                    },
                  ),
                ],
              ),

              // Show validation error if category is not selected
              if (!_isCategoryValid)
                Text(
                  'Please select a valid category',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              SizedBox(height: 16),

              // Image picker button (aligned to center)
              _imageBytes == null
                  ? ElevatedButton(
                    onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.deepOrange, // Button background color
                  foregroundColor: Colors.white, // Button text color
                  padding: EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 32,
                  ), // Adjust padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                ),
                    child: Text(
                        'Pick Image',
                      style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w700
                      ),),
                  )
                  : Column(
                    children: [
                      Image.memory(
                        _imageBytes!,
                        height: 200,
                        width: 450,
                        fit: BoxFit.cover,
                      ),
                      ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          Colors.deepOrange, // Button background color
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Change Image',
                          style: GoogleFonts.comicNeue(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.w700
                          ),),
                      ),
                    ],
                  ),
              SizedBox(height: 16),

              // Submit post button (centered)
              Center(
                child: ElevatedButton(
                  onPressed: _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.deepOrange, // Button background color
                    foregroundColor: Colors.white, // Button text color
                    padding: EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 32,
                    ), // Adjust padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                  ),
                  child: Text(
                      'Create Post',
                      style: GoogleFonts.comicNeue(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w700
                      ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
