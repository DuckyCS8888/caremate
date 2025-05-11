import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'createPost.dart'; // Import your CreatePostPage
import 'Comment.dart';
import 'notification.dart';

class CommunityForum extends StatefulWidget {
  @override
  _CommunityForumState createState() => _CommunityForumState();
}

class _CommunityForumState extends State<CommunityForum> {
  String selectedCategory = ''; // Track selected category
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  bool _hasError = false;
  bool _hasUnreadNotifications = false; // Track unread notifications
  String _errorMessage = '';
  Map<String, String> _usernames = {}; // A map to store fetched usernames
  Map<String, String> _profilePics = {}; // A map to store profile picture URLs

  // Step 1: Add real-time listeners to listen for likes and comments
  void _listenForLikesAndComments() {
    // Listen for new likes on the logged-in user's posts
    FirebaseFirestore.instance
        .collection('users')
        .doc(
          FirebaseAuth.instance.currentUser!.uid,
        ) // Listen only for the logged-in user's posts
        .collection('posts')
        .snapshots()
        .listen((postSnapshot) {
          postSnapshot.docChanges.forEach((change) {
            if (change.type == DocumentChangeType.modified) {
              // Check if there are new likes or comments
              if (change.doc.data()?['likes'] != null &&
                  change.doc.data()?['likes'].length > 0) {
                _setUnreadNotification();
              }
            }
          });
        });

    // Listen for new comments on the logged-in user's posts
    FirebaseFirestore.instance
        .collection('users')
        .doc(
          FirebaseAuth.instance.currentUser!.uid,
        ) // Listen only for the logged-in user's posts
        .collection('posts')
        .snapshots()
        .listen((postSnapshot) {
          postSnapshot.docChanges.forEach((change) {
            if (change.type == DocumentChangeType.modified) {
              // Check if there are new comments
              if (change.doc.data()?['comments'] != null &&
                  change.doc.data()?['comments'].isNotEmpty) {
                _setUnreadNotification();
              }
            }
          });
        });
  }

  // Step 2: Update the notification state
  void _setUnreadNotification() {
    setState(() {
      _hasUnreadNotifications =
          true; // Mark as true when there is a new like or comment
    });
  }

  // Step 3: Handle notification icon tap and mark notifications as read
  void _markNotificationsAsRead() {
    setState(() {
      _hasUnreadNotifications = false; // Mark notifications as read
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchPosts(); // Fetch posts when the widget is initialized
    _listenForLikesAndComments(); // Start listening for likes and comments changes
    _checkUnreadNotifications(); // Check for unread notifications
  }

  // Fetch posts based on selected category
  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      // Preparing the query
      Query query = FirebaseFirestore.instance.collectionGroup('posts');

      // Filter by selected category if any
      if (selectedCategory.isNotEmpty) {
        query = query.where('category', isEqualTo: selectedCategory);
      }

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

  // Real-time listener to check if there are any unread notifications
  Future<void> _checkUnreadNotifications() async {
    try {
      FirebaseFirestore.instance
          .collection('notifications')
          .where(
            'userId',
            isEqualTo: FirebaseAuth.instance.currentUser!.uid,
          ) // Check for current user's notifications
          .where('isRead', isEqualTo: false) // Check for unread notifications
          .snapshots()
          .listen((snapshot) {
            setState(() {
              _hasUnreadNotifications = snapshot.docs.isNotEmpty;
            });
          });
    } catch (e) {
      print('Error fetching notifications: $e');
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
      backgroundColor: Colors.white,
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
          // Notification button in AppBar
          IconButton(
            icon: _hasUnreadNotifications
                ? Stack(
              children: [
                Icon(Icons.notifications),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              ],
            )
                : Icon(Icons.notifications),
            onPressed: () {
              // Mark notifications as read when the user interacts with the bell (without navigating)
              _markNotificationsAsRead();
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
        backgroundColor:
            isSelected
                ? Colors.deepOrangeAccent
                : Colors.white, // Orange when selected, White when not selected
        foregroundColor:
            isSelected
                ? Colors.white
                : Colors
                    .black, // White text when selected, Black text when not selected
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  int commentCount = 0; // Track the comment count
  int likeCount = 0; // Track the like count

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
    _fetchCommentCount(); // Fetch the comment count when the post card is created
    _fetchLikeCount(); // Fetch like count for the post
  }

  // Fetch the comment count for this post
  Future<void> _fetchCommentCount() async {
    try {
      // Reference to the comments collection for this post
      DocumentReference postRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('posts')
          .doc(widget.postId);

      // Listen to the changes in the comments collection in real-time
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .snapshots()
          .listen((snapshot) {
            setState(() {
              commentCount =
                  snapshot
                      .docs
                      .length; // Set the number of documents in the comments collection
            });
          });
    } catch (e) {
      print('Error fetching comment count: $e');
    }
  }

  // Fetch the like count for this post (real-time listener)
  Future<void> _fetchLikeCount() async {
    try {
      // Reference to the likes collection for this post
      DocumentReference postRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('posts')
          .doc(widget.postId);

      // Listen to the changes in the likes collection in real-time
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('posts')
          .doc(widget.postId)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              var data = snapshot.data() as Map<String, dynamic>;
              List likesList = data['likes'] ?? [];
              setState(() {
                likeCount = likesList.length; // Update like count
              });
            }
          });
    } catch (e) {
      print('Error fetching like count: $e');
    }
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

  // Step 1: Add like to the post (with username and profilePic)
  Future<void> _addLike(String postId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      String username = userDoc['username'] ?? 'Anonymous';
      String profilePic = userDoc['profilePic'] ?? '';


      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .add({
        'userID': currentUser.uid,
        'username': username,
        'profilePic': profilePic,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _createNotification(postId, 'like');
    } catch (e) {
      print("Error adding like: $e");
    }
  }

  Future<void> _addComment(String postId, String commentText) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      String username = userDoc['username'] ?? 'Anonymous';
      String profilePic = userDoc['profilePic'] ?? '';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'userID': currentUser.uid,
        'username': username,
        'profilePic': profilePic,
        'comment': commentText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 创建评论通知
      _createNotification(postId, 'comment');
    } catch (e) {
      print("Error adding comment: $e");
    }
  }


  // 创建通知
  Future<void> _createNotification(String postId, String type) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      String username = userDoc['username'] ?? 'Anonymous';
      String profilePic = userDoc['profilePic'] ?? '';

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'postId': postId,
        'type': type,  // like 或 comment
        'username': username,  // include username
        'profilePic': profilePic,  // include profilePic
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false, // default as unread
      });
    } catch (e) {
      print("Error creating notification: $e");
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
      child:
          widget.profilePicUrl.isNotEmpty
              ? Image.memory(
                base64Decode(widget.profilePicUrl),
                height: 45,
                width: 45,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person); // Default icon if image fails
                },
              )
              : Icon(Icons.person, size: 45),
    );

    // Safely decode the base64 image for the post
    Widget imageWidget = SizedBox.shrink();
    if (widget.image.isNotEmpty) {
      try {
        Uint8List decodedImage = base64Decode(widget.image);
        imageWidget = Image.memory(
          decodedImage,
          height: 225,
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
            title: Text(
              widget.username,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ), // Username style
            ),
            subtitle: Text(
              '${widget.location}',
              style: GoogleFonts.merriweather(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ), // Location style
            ),
            trailing: Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ), // Timestamp style
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              widget.content,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ), // Post content style
            ),
          ),
          widget.image.isNotEmpty ? imageWidget : SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Likes section
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: _toggleLike, // Toggle like
                    ),
                    Text(
                      '$likeCount Likes', // Display the real-time like count
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ), // Likes text style: bold, black, weight 600
                    ),
                  ],
                ),
                // Comment section
                SizedBox(width: 16),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.comment_outlined,
                        color: Colors.black,
                      ), // Comment icon
                      onPressed: () {
                        // Fetch the postOwnerID from the post data (you already have this in the post)
                        String postOwnerID =
                            widget
                                .userId; // Assuming you store the userID in the post object
                        // Navigate to the ViewCommentsPage when comment icon is clicked
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ViewCommentsPage(
                                  postID: widget.postId, // Pass postId
                                  postOwnerID:
                                      postOwnerID, // Pass postOwnerID (the user ID of the post owner)
                                ),
                          ),
                        );
                      },
                    ),
                    Text(
                      '$commentCount Comments', // Display the number of comments
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ), // Comment count style
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
