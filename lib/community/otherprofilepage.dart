import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projects/community/Comment.dart';

class OtherProfilePage extends StatefulWidget {
  final String userId;  // User ID to fetch their profile

  OtherProfilePage({required this.userId});

  @override
  _OtherProfilePageState createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = '';
  String _job = '';
  String _bio = '';
  String _profilePicUrl = ''; // Profile picture URL as base64 string
  Uint8List? _profilePic; // To hold decoded image data
  int _postCount = 0; // For storing total post count
  int _likesCount = 0; // For storing total likes count
  List<DocumentSnapshot> _userPosts = [];  // To store user's posts

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load data when the page is loaded
    _loadUserPosts(); // Load posts and calculate likes when the page is loaded
  }

  // Function to load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      // Reference to the user's document in Firestore using the passed userId
      DocumentReference userDocRef = _firestore.collection("users").doc(widget.userId);

      // Fetch user data from Firestore
      DocumentSnapshot snapshot = await userDocRef.get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;

        setState(() {
          _username = data['username'] ?? 'No username';
          _job = data['job'] ?? 'No job';
          _bio = data['bio'] ?? 'No bio';
          _profilePicUrl = data['profilePic'] ?? ''; // Base64 string
          _profilePic = _profilePicUrl.isNotEmpty
              ? base64Decode(_profilePicUrl)
              : null; // Decode the base64 string
        });
      } else {
        print('No data found for user ${widget.userId}');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Function to load user posts from Firestore and calculate the total likes
  Future<void> _loadUserPosts() async {
    try {
      QuerySnapshot postSnapshot = await _firestore.collection('users').doc(widget.userId).collection('posts').get();

      setState(() {
        _userPosts = postSnapshot.docs;
        _postCount = _userPosts.length;

        // Initialize total likes count
        _likesCount = 0;

        // Loop through each post to calculate likes
        _userPosts.forEach((post) {
          // Check if 'likes' exists for the post, else set it to 0
          var likes = post['likes'] != null ? post['likes'] : 0;

          // If likes is a list, we count the number of likes in the list
          if (likes is List) {
            _likesCount += likes.length;
          } else if (likes is int) {
            _likesCount += likes;
          }
        });
      });
    } catch (e) {
      print('Error loading user posts: $e');
    }
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

  // Function to show the post details in a dialog
  void _showPostDetailsDialog(DocumentSnapshot post) {
    String formattedDate = 'Unknown time';
    if (post['timestamp'] != null) {
      DateTime dateTime = post['timestamp'].toDate();
      formattedDate =
      '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    // Initialize the image widget for the post
    Widget imageWidget = SizedBox.shrink();
    if (post['image'] != null) {
      try {
        Uint8List decodedImage = base64Decode(post['image']);
        imageWidget = Image.memory(
          decodedImage,
          width: double.infinity,
          fit: BoxFit.contain,
        );
      } catch (e) {
        imageWidget = Container(
          height: 100,
          color: Colors.grey[300],
          child: Center(child: Text('Invalid image format')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isLiked = false;
        var likeCount = post['likes'] != null && post['likes'] is List
            ? post['likes'].length
            : 0;

        var _commentController = TextEditingController(); // Initialize the comment controller here

        // Listen to real-time likes and comments updates
        FirebaseFirestore.instance
            .collection('users')
            .doc(post['userID'])
            .collection('posts')
            .doc(post.id)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            var data = snapshot.data() as Map<String, dynamic>;
            List likesList = data['likes'] ?? [];
            setState(() {
              isLiked = likesList.contains(FirebaseAuth.instance.currentUser!.uid);
              likeCount = likesList.length;
            });
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent, // Transparent background for dialog
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop(); // Close the dialog when tapped outside
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 800,
                    height: 600, // Increase the height of the dialog to fit the image and comments
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage: _profilePic != null
                                  ? MemoryImage(_profilePic!)
                                  : NetworkImage('https://via.placeholder.com/150'),
                            ),
                            title: Text(
                              _username,
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              post['location'] ?? 'Unknown',
                              style: GoogleFonts.merriweather(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            trailing: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            post['content'] ?? '',
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                          SizedBox(height: 10),
                          imageWidget,
                          SizedBox(height: 10),
                          // Likes and Comments section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Like Button
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: isLiked ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () async {
                                      // Toggle like on this post
                                      DocumentReference postRef = FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(post['userID'])
                                          .collection('posts')
                                          .doc(post.id);

                                      if (isLiked) {
                                        await postRef.update({
                                          'likes': FieldValue.arrayRemove([FirebaseAuth.instance.currentUser!.uid]),
                                        });
                                      } else {
                                        await postRef.update({
                                          'likes': FieldValue.arrayUnion([FirebaseAuth.instance.currentUser!.uid]),
                                        });
                                      }
                                    },
                                  ),
                                  Text(
                                    '$likeCount Likes',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              // Comment Section
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.comment_outlined, color: Colors.black), // Comment icon
                                    onPressed: () {
                                      // Navigate to the comments screen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ViewCommentsPage(
                                            postID: post.id,  // Pass postId
                                            postOwnerID: post['userID'], // Pass postOwnerID
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(post['userID'])
                                        .collection('posts')
                                        .doc(post.id)
                                        .collection('comments')
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }
                                      if (snapshot.hasError) {
                                        return Text('Error loading comments');
                                      }

                                      // Count the number of documents (comments) in the collection
                                      int commentCount = snapshot.data?.docs.length ?? 0;
                                      return Text(
                                        '$commentCount Comments',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Profile',
          style: GoogleFonts.comicNeue(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.deepOrange,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Picture
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

              // Posts and Likes count
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        '$_postCount',
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Posts',
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 30),
                  Column(
                    children: [
                      Text(
                        '$_likesCount',
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Likes',
                        style: GoogleFonts.comicNeue(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Display posts in GridView
              SizedBox(height: 20),  // Add spacing between buttons and post images
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _userPosts.length,
                itemBuilder: (context, index) {
                  String imageUrl = _userPosts[index]['image']; // Assuming the post has an 'image' field
                  return GestureDetector(
                    onTap: () => _showPostDetailsDialog(_userPosts[index]), // Show post details dialog
                    child: Image.memory(
                      base64Decode(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
