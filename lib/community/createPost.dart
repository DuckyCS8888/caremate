import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';  // For base64 encoding
import 'dart:typed_data';  // For Uint8List
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  TextEditingController _contentController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  Uint8List? _imageBytes;  // Store the post image as Uint8List
  String _selectedLocation = 'Select Location';  // Default location
  String _selectedCategory = 'Select Category'; // Default category
  bool _isLocationValid = true;  // Validity of the location field
  bool _isCategoryValid = true;  // Validity of the category field

  // Maximum allowed image size for uploading to Firestore (e.g., 750KB)
  final int maxImageSizeInBytes = 750 * 1024;

  // Function to pick and compress the image
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

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
          final sizeInKB = (compressedImage.lengthInBytes / 1024).toStringAsFixed(1);
          final limitInKB = (maxImageSizeInBytes / 1024).toStringAsFixed(0);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image too large ($sizeInKB KB). Max ~${limitInKB}KB allowed.')));
          return; // Exit if image is too large
        }

        // Set the compressed image in the state
        setState(() {
          _imageBytes = compressedImage;
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error picking/compressing image: ${e.toString()}')),
    );
    print("Image picking/compression error: $e");
  }
  }
  }

  Future<String?> _getUsername() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return userDoc['profilePic'];  // Assuming the base64 profile image is stored under 'profilePic'
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
    if (_contentController.text.isEmpty || _imageBytes == null || _selectedLocation == 'Select Location' || _selectedCategory == 'Select Category') {
      setState(() {
        _isLocationValid = _selectedLocation != 'Select Location';
        _isCategoryValid = _selectedCategory != 'Select Category';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all fields, including selecting a location and category.')));
      return;
    }

    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No user is logged in')));
      return;
    }

    // Get the username and profile picture (base64) from Firestore
    String? username = await _getUsername();
    String? profilePicBase64 = await _getProfilePicBase64();

    if (username == null || profilePicBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Username or profile picture not found')));
      return;
    }

    // Convert the post image to base64 before storing in Firestore
    String base64Image = base64Encode(_imageBytes!);

    // Get the current timestamp
    Timestamp timestamp = Timestamp.now();

    // Add the post data to Firestore
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('posts').add({
        'content': _contentController.text,
        'image': base64Image,  // Store the post image in base64
        'timestamp': timestamp,
        'likes': [],
        'location': _selectedLocation,
        'category': _selectedCategory, // Store the selected category
        'userID': user.uid,  // Store the user's UID
        'username': username, // Store the username
        'profilePic': profilePicBase64,  // Store the user's profile picture in base64
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post created successfully')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating post')));
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input for post content
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),

            // Location Dropdown
            Row(
              children: [
                Text('Location:'),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedLocation,
                  items: <String>[
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
                    'Kuala Lumpur'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLocation = newValue!;
                      _isLocationValid = _selectedLocation != 'Select Location';  // Validate location
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

            // Category Dropdown
            Row(
              children: [
                Text('Category:'),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: <String>[
                    'Select Category',
                    'Food',
                    'Fund',
                    'Shelter',
                    'Health',
                    'Education'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                      _isCategoryValid = _selectedCategory != 'Select Category';  // Validate category
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

            // Image picker button
            _imageBytes == null
                ? ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            )
                : Column(
              children: [
                Image.memory(_imageBytes!, height: 200, width: 200, fit: BoxFit.cover),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Change Image'),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Submit post button
            ElevatedButton(
              onPressed: _createPost,
              child: Text('Create Post'),
            ),
          ],
        ),
      ),
    );
  }
}


