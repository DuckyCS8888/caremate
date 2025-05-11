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
  TextEditingController _commentController = TextEditingController();  // Controller for comment input
  Uint8List? _imageBytes;
  String _selectedLocation = 'Select Location';
  String _selectedCategory = 'Select Category';
  bool _isLocationValid = true;
  bool _isCategoryValid = true;
  final int maxImageSizeInBytes = 750 * 1024;

  // Function to pick and compress the image
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final imageBytes = await pickedFile.readAsBytes();
        final compressedImage = await FlutterImageCompress.compressWithList(
          imageBytes,
          minHeight: 800,
          minWidth: 800,
          quality: 85,
        );

        if (compressedImage.lengthInBytes > maxImageSizeInBytes) {
          final sizeInKB = (compressedImage.lengthInBytes / 1024).toStringAsFixed(1);
          final limitInKB = (maxImageSizeInBytes / 1024).toStringAsFixed(0);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image too large ($sizeInKB KB). Max ~${limitInKB}KB allowed.'))
          );
          return;
        }

        setState(() {
          _imageBytes = compressedImage;
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking/compressing image: ${e.toString()}')));
        print("Image picking/compression error: $e");
      }
    }
  }

  // Function to get the current user's username
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

  // Function to get the current user's profile picture in base64
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

  // Function to create the post in Firestore
  Future<void> _createPost() async {
    if (_contentController.text.isEmpty || _imageBytes == null || _selectedLocation == 'Select Location' || _selectedCategory == 'Select Category') {
      setState(() {
        _isLocationValid = _selectedLocation != 'Select Location';
        _isCategoryValid = _selectedCategory != 'Select Category';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill in all fields, including selecting a location and category.')));
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No user is logged in')));
      return;
    }

    String? username = await _getUsername();
    String? profilePicBase64 = await _getProfilePicBase64();

    if (username == null || profilePicBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Username or profile picture not found')));
      return;
    }

    String base64Image = base64Encode(_imageBytes!);

    Timestamp timestamp = Timestamp.now();

    try {
      // Add the post to Firestore
      DocumentReference postRef = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('posts').add({
        'content': _contentController.text,
        'image': base64Image,
        'timestamp': timestamp,
        'likes': [],
        'location': _selectedLocation,
        'category': _selectedCategory,
        'userID': user.uid,
        'username': username,
        'profilePic': profilePicBase64,
        'commentCount': 0,  // Initialize comment count
      });

      // Clear fields after creating post
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post created successfully')));
      _contentController.clear();
      _locationController.clear();
      _commentController.clear();
      setState(() {
        _imageBytes = null;
        _selectedLocation = 'Select Location';
        _selectedCategory = 'Select Category';
        _isLocationValid = true;
        _isCategoryValid = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating post')));
      print(e.toString());
    }
  }

  // Add comment to Firestore
  Future<void> _addComment(String content, String postId) async {
    if (content.isNotEmpty) {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No user is logged in')));
        return;
      }

      try {
        DocumentReference postRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('posts').doc(postId);
        CollectionReference commentsRef = postRef.collection('comments');

        // Add comment to Firestore
        await commentsRef.add({
          'userID': user.uid,
          'content': content,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Increment the comment count
        await postRef.update({
          'commentCount': FieldValue.increment(1),
        });

        // Clear comment input field after submitting
        setState(() {
          _commentController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comment added successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding comment')));
        print(e.toString());
      }
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
            // Post content input
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'What\'s on your mind?', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            SizedBox(height: 16),

            // Location dropdown
            Row(
              children: [
                Text('Location:'),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedLocation,
                  items: <String>[
                    'Select Location',
                    'Johor', 'Kedah', 'Kelantan', 'Melaka', 'Negeri Sembilan', 'Pahang', 'Perak', 'Perlis', 'Penang', 'Sabah', 'Sarawak', 'Selangor', 'Terengganu', 'Labuan', 'Kuala Lumpur'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLocation = newValue!;
                      _isLocationValid = _selectedLocation != 'Select Location';
                    });
                  },
                ),
              ],
            ),
            if (!_isLocationValid) Text('Please select a valid location', style: TextStyle(color: Colors.red, fontSize: 12)),
            SizedBox(height: 16),

            // Category dropdown
            Row(
              children: [
                Text('Category:'),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: <String>['Select Category', 'Food', 'Fund', 'Shelter', 'Health', 'Education'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                      _isCategoryValid = _selectedCategory != 'Select Category';
                    });
                  },
                ),
              ],
            ),
            if (!_isCategoryValid) Text('Please select a valid category', style: TextStyle(color: Colors.red, fontSize: 12)),
            SizedBox(height: 16),

            // Image picker
            _imageBytes == null
                ? ElevatedButton(onPressed: _pickImage, child: Text('Pick Image'))
                : Column(
              children: [
                Image.memory(_imageBytes!, height: 200, width: 200, fit: BoxFit.cover),
                ElevatedButton(onPressed: _pickImage, child: Text('Change Image')),
              ],
            ),
            SizedBox(height: 16),

            // Comment input and submit button
            TextField(
              controller: _commentController,
              decoration: InputDecoration(labelText: 'Add a comment', border: OutlineInputBorder()),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                String postId = "your_post_id_here";  // Replace with the actual post ID
                _addComment(_commentController.text, postId);
              },
              child: Text('Add Comment'),
            ),
            SizedBox(height: 16),

            // Submit post button
            ElevatedButton(onPressed: _createPost, child: Text('Create Post')),
          ],
        ),
      ),
    );
  }
}


