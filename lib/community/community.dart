import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'createPost.dart'; // Import your CreatePostPage

class CommunityForum extends StatefulWidget {
  @override
  _CommunityForumState createState() => _CommunityForumState();
}

class _CommunityForumState extends State<CommunityForum> {
  String selectedCategory = ''; // Track selected category
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, String> _usernames = {}; // A map to store fetched usernames
  Map<String, String> _profilePics = {}; // A map to store profile picture URLs

  @override
  void initState() {
    super.initState();
    _fetchPosts(); // Fetch posts when the widget is initialized
  }

  // Fetch all available posts from Firestore
  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      // Preparing the query
      Query query = FirebaseFirestore.instance.collectionGroup('posts');

      // Add ordering by timestamp
      query = query.orderBy('timestamp', descending: true);

      // Execute the query
      QuerySnapshot querySnapshot = await query.get();

      // Process the results
      List<Map<String, dynamic>> posts = [];
      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        // Add document ID to the data for reference
        data['id'] = doc.id;
        posts.add(data);
      }

      // Fetch the username and profile picture for each post using the userID
      await _fetchUsernamesAndPics(posts);

      if (mounted) {
        setState(() {
          _posts = posts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Error fetching posts: $e';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage)));
      }
    }
  }

  // Fetch all usernames and profile pictures for users who posted
  Future<void> _fetchUsernamesAndPics(List<Map<String, dynamic>> posts) async {
    try {
      Map<String, String> usernameMap = {};
      Map<String, String> profilePicMap = {};

      // Fetch all users from the 'users' collection
      for (var post in posts) {
        String userId = post['userID']; // Get userID from post data
        if (!usernameMap.containsKey(userId)) {
          DocumentSnapshot userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get();
          if (userDoc.exists) {
            usernameMap[userId] =
                userDoc['username'] ?? 'Anonymous'; // Store username by userID
            profilePicMap[userId] =
                userDoc['profilePic'] ??
                ''; // Store profile picture URL by userID
          } else {
            usernameMap[userId] =
                'Anonymous'; // Fallback if username doesn't exist
            profilePicMap[userId] =
                ''; // Fallback if profile picture doesn't exist
          }
        }
      }

      setState(() {
        _usernames = usernameMap; // Store the map in the state
        _profilePics = profilePicMap; // Store the profile picture URLs
      });
    } catch (e) {
      print('Error fetching usernames and profile pictures: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "CareMate",
          style: GoogleFonts.comicNeue(
            fontSize: 35,
            fontWeight:
                FontWeight.w900, // Replace with your desired font family
            color: Colors.deepOrange,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          // Refresh button
          IconButton(icon: Icon(Icons.refresh), onPressed: _fetchPosts),
          // Notification button
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Add the functionality for the notification button
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories horizontal scrollable row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 8),
                  // All categories option
                  CategoryButton('All', (category) {
                    setState(() {
                      selectedCategory = '';
                    });
                    _fetchPosts();
                  }, isSelected: selectedCategory.isEmpty),
                  SizedBox(width: 8),
                  CategoryButton(
                    'Food',
                    _changeCategory,
                    isSelected: selectedCategory == 'Food',
                  ),
                  SizedBox(width: 8),
                  CategoryButton(
                    'Fund',
                    _changeCategory,
                    isSelected: selectedCategory == 'Fund',
                  ),
                  SizedBox(width: 8),
                  CategoryButton(
                    'Health',
                    _changeCategory,
                    isSelected: selectedCategory == 'Health',
                  ),
                  SizedBox(width: 8),
                  CategoryButton(
                    'Education',
                    _changeCategory,
                    isSelected: selectedCategory == 'Education',
                  ),
                  SizedBox(width: 8),
                  CategoryButton(
                    'Shelter',
                    _changeCategory,
                    isSelected: selectedCategory == 'Shelter',
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ),

          // Posts List
          Expanded(
            child:
                _loading
                    ? Center(child: CircularProgressIndicator())
                    : _hasError
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Failed to load posts'),
                          ElevatedButton(
                            onPressed: _fetchPosts,
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _posts.isEmpty
                    ? Center(child: Text('No posts available'))
                    : RefreshIndicator(
                      onRefresh: _fetchPosts,
                      child: ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          var post = _posts[index];
                          String username =
                              _usernames[post['userID']] ??
                              'Anonymous'; // Get username for each post
                          String profilePicUrl =
                              _profilePics[post['userID']] ??
                              ''; // Get profile picture URL
                          return PostCard(
                            location: post['location'] ?? 'Unknown',
                            content: post['content'] ?? '',
                            image: post['image'] ?? '',
                            likes:
                                post['likes'] != null
                                    ? (post['likes'] is List
                                        ? post['likes'].length
                                        : 0)
                                    : 0,
                            timestamp:
                                post['timestamp'] is Timestamp
                                    ? post['timestamp'] as Timestamp
                                    : null,
                            postId: post['id'],
                            userId: post['userID'] ?? '',
                            username:
                                username, // Pass the correct username here
                            profilePicUrl:
                                profilePicUrl, // Pass the profile picture URL
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to create post page and refresh when returning
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostPage()),
          );

          // Refresh posts if a new post was created
          if (result == true) {
            _fetchPosts();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Update the selected category
  void _changeCategory(String category) {
    setState(() {
      selectedCategory = category;
    });
    _fetchPosts();
  }
}

class CategoryButton extends StatelessWidget {
  final String categoryName;
  final Function(String) onCategorySelected;
  final bool isSelected;

  CategoryButton(
    this.categoryName,
    this.onCategorySelected, {
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        onCategorySelected(categoryName);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
      child: Text(categoryName),
    );
  }
}

class PostCard extends StatefulWidget {
  final String location;
  final String content;
  final String image; // Base64 image string
  final int likes;
  final Timestamp? timestamp;
  final String postId;
  final String userId;
  final String username; // Receive username as a parameter
  final String profilePicUrl; // Receive profile picture URL as a parameter

  PostCard({
    required this.location,
    required this.content,
    required this.image,
    required this.likes,
    required this.timestamp,
    required this.postId,
    required this.userId,
    required this.username, // Accept username here
    required this.profilePicUrl, // Accept profile picture URL here
  });

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  // Check if the current user has already liked the post
  Future<void> _checkIfLiked() async {
    try {
      DocumentReference postRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('posts')
          .doc(widget.postId);

      var postDoc = await postRef.get();
      if (postDoc.exists) {
        var data = postDoc.data() as Map<String, dynamic>;
        List likesList = data['likes'] ?? [];
        setState(() {
          isLiked = likesList.contains(FirebaseAuth.instance.currentUser!.uid);
        });
      }
    } catch (e) {
      print('Error checking if post is liked: $e');
    }
  }

  // Toggle the like button and update Firestore
  Future<void> _toggleLike() async {
    try {
      DocumentReference postRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('posts')
          .doc(widget.postId);

      if (isLiked) {
        // If the user already liked, remove the like
        postRef.update({
          'likes': FieldValue.arrayRemove([
            FirebaseAuth.instance.currentUser!.uid,
          ]),
        });
      } else {
        // If the user has not liked, add the like
        postRef.update({
          'likes': FieldValue.arrayUnion([
            FirebaseAuth.instance.currentUser!.uid,
          ]),
        });
      }

      // Update the local state to reflect the change
      setState(() {
        isLiked = !isLiked;
      });
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format the timestamp
    String formattedDate = 'Unknown time';
    if (widget.timestamp != null) {
      DateTime dateTime = widget.timestamp!.toDate();
      formattedDate =
          '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    // Safely decode the base64 profile image
    Widget profilePicWidget = ClipOval(
      // Clip the profile picture into a circular shape
      child:
          widget.profilePicUrl.isNotEmpty
              ? Image.memory(
                base64Decode(widget.profilePicUrl),
                height: 40,
                width: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person); // Default icon if image fails
                },
              )
              : Icon(
                Icons.person,
                size: 40,
              ), // Default avatar if no profile picture is provided
    );

    // Safely decode the base64 image for the post
    Widget imageWidget = SizedBox.shrink();
    if (widget.image.isNotEmpty) {
      try {
        Uint8List decodedImage = base64Decode(widget.image);
        imageWidget = Image.memory(
          decodedImage,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 100,
              color: Colors.grey[300],
              child: Center(child: Text('Image could not be loaded')),
            );
          },
        );
      } catch (e) {
        imageWidget = Container(
          height: 100,
          color: Colors.grey[300],
          child: Center(child: Text('Invalid image format')),
        );
      }
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: profilePicWidget, // Display profile picture
            title: Text(widget.username),
            subtitle: Text('${widget.location}'),
            trailing: Text(formattedDate, style: TextStyle(fontSize: 12)),
          ),
          // Show post content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(widget.content, style: TextStyle(fontSize: 16)),
          ),
          // Show image if available
          widget.image.isNotEmpty ? imageWidget : SizedBox.shrink(),
          // Likes and interaction buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: _toggleLike, // Toggle like
                    ),
                    Text('${widget.likes} Likes'),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.comment_outlined),
                  onPressed: () {
                    // Implement comments functionality
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
