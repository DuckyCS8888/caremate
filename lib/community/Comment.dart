import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewCommentsPage extends StatefulWidget {
  final String postID; // Post ID passed from the previous page
  final String postOwnerID; // Post owner's ID (User2 or User1)

  ViewCommentsPage({required this.postID, required this.postOwnerID});

  @override
  _ViewCommentsPageState createState() => _ViewCommentsPageState();
}

class _ViewCommentsPageState extends State<ViewCommentsPage> {
  TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _fetchComments(); // Fetch comments when the page is loaded
  }

  // Fetch comments for the specific post
  Future<void> _fetchComments() async {
    try {
      QuerySnapshot commentSnapshot = await FirebaseFirestore.instance
          .collection('users')  // Users collection
          .doc(widget.postOwnerID)  // User owning the post
          .collection('posts')  // Posts sub-collection
          .doc(widget.postID)  // Specific post
          .collection('comments')  // Comments sub-collection
          .orderBy('timestamp', descending: true)  // Order by timestamp
          .get();

      setState(() {
        _comments = commentSnapshot.docs
            .map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['commentID'] = doc.id;  // Add the Firestore comment ID to the data
          return data;
        })
            .toList();
      });
    } catch (e) {
      print("Error fetching comments: $e");
    }
  }

  // Add a comment to the post
  Future<void> _addComment() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && _commentController.text.isNotEmpty) {
      try {
        // Fetch the user's username and profile picture
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)  // Fetch the user document by UID
            .get();

        String username = userDoc['username'] ?? 'Anonymous'; // Default to 'Anonymous' if not found
        String profilePic = userDoc['profilePic'] ?? '';  // Fetch the profile picture URL (base64 encoded)

        Timestamp timestamp = Timestamp.now();

        // Add the comment to Firestore under the user's post
        await FirebaseFirestore.instance
            .collection('users')  // Users collection
            .doc(widget.postOwnerID)  // Post owner (user 2)
            .collection('posts')  // Posts sub-collection
            .doc(widget.postID)  // Specific post
            .collection('comments')  // Comments sub-collection
            .add({
          'comment': _commentController.text,
          'userID': user.uid,
          'username': username,
          'profilePic': profilePic,  // Store the user's profile picture (base64 encoded)
          'timestamp': timestamp,
          'postOwnerID': widget.postOwnerID,  // Store post owner ID
        }).then((docRef) async {
          print("Comment added with ID: ${docRef.id}");

          // Increment the comment count for the post
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.postOwnerID)
              .collection('posts')
              .doc(widget.postID)
              .update({
            'commentsCount': FieldValue.increment(1), // Increment comment count
          });
        }).catchError((e) {
          print("Error adding comment: $e");
        });

        _commentController.clear();  // Clear the text field after submitting the comment
        _fetchComments();  // Refresh the comment list
      } catch (e) {
        print("Error adding comment: $e");
      }
    } else {
      print('No user logged in or comment text is empty');
    }
  }

  // Decode the base64 profile picture to display in the comment section
  ImageProvider _decodeBase64ProfilePic(String base64String) {
    if (base64String.isEmpty) {
      return AssetImage('assets/images/default_profile.png'); // Return a default image if empty
    }
    try {
      Uint8List bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return AssetImage('assets/images/default_profile.png'); // Return default image if error occurs
    }
  }

  // Delete a comment (only the comment creator can delete it)
  Future<void> _deleteComment(String commentID) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Find the comment and check if it's the current user's comment
        DocumentSnapshot commentSnapshot = await FirebaseFirestore.instance
            .collection('users')  // Users collection
            .doc(widget.postOwnerID)  // Post owner
            .collection('posts')  // Posts sub-collection
            .doc(widget.postID)  // Specific post
            .collection('comments')  // Comments sub-collection
            .doc(commentID) // Use commentID passed from the ListTile
            .get();

        if (commentSnapshot.exists && commentSnapshot['userID'] == user.uid) {
          // If the current user is the commenter, delete the comment
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.postOwnerID)
              .collection('posts')
              .doc(widget.postID)
              .collection('comments')
              .doc(commentID) // Deleting the comment by ID
              .delete();

          print('Comment deleted successfully');
          _fetchComments(); // Refresh the comment list
        } else {
          print('You can only delete your own comments');
        }
      } catch (e) {
        print("Error deleting comment: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View Comments')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display the list of comments
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  var comment = _comments[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: _decodeBase64ProfilePic(comment['profilePic']),
                      child: comment['profilePic'].isEmpty
                          ? Icon(Icons.person)
                          : null,
                    ),
                    title: Text(comment['username']),
                    subtitle: Text(comment['comment']),
                    trailing: Text(
                      // Format the timestamp (if needed)
                      '${(comment['timestamp'] as Timestamp).toDate()}',
                      style: TextStyle(fontSize: 12),
                    ),
                    // Delete button (only for the commenter)
                    onLongPress: () {
                      if (comment['userID'] == FirebaseAuth.instance.currentUser?.uid) {
                        _deleteComment(comment['commentID']);  // Use comment['commentID']
                      }
                    },
                  );
                },
              ),
            ),
            // Comment input field
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Add a comment...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addComment,
              child: Text('Add Comment'),
            ),
          ],
        ),
      ),
    );
  }
}
