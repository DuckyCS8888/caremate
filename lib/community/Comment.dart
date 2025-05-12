import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting
import 'package:google_fonts/google_fonts.dart';

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

  // Function to show the confirmation dialog
  void _showDeleteConfirmationDialog(BuildContext context, String commentID) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Delete',
            style: GoogleFonts.comicNeue(
              fontSize: 30,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this comment?',
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Button background color
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _deleteComment(commentID); // Delete the comment
                Navigator.of(context).pop(); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Button background color
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Fetch comments for the specific post
  Future<void> _fetchComments() async {
    try {
      QuerySnapshot commentSnapshot =
          await FirebaseFirestore.instance
              .collection('users') // Users collection
              .doc(widget.postOwnerID) // User owning the post
              .collection('posts') // Posts sub-collection
              .doc(widget.postID) // Specific post
              .collection('comments') // Comments sub-collection
              .orderBy('timestamp', descending: true) // Order by timestamp
              .get();

      setState(() {
        _comments =
            commentSnapshot.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              data['commentID'] =
                  doc.id; // Add the Firestore comment ID to the data
              return data;
            }).toList();
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
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid) // Fetch the user document by UID
                .get();

        String username =
            userDoc['username'] ??
            'Anonymous'; // Default to 'Anonymous' if not found
        String profilePic =
            userDoc['profilePic'] ??
            ''; // Fetch the profile picture URL (base64 encoded)

        Timestamp timestamp = Timestamp.now();

        // Add the comment to Firestore under the user's post
        await FirebaseFirestore.instance
            .collection('users') // Users collection
            .doc(widget.postOwnerID) // Post owner (user 2)
            .collection('posts') // Posts sub-collection
            .doc(widget.postID) // Specific post
            .collection('comments') // Comments sub-collection
            .add({
              'comment': _commentController.text,
              'userID': user.uid,
              'username': username,
              'profilePic':
                  profilePic, // Store the user's profile picture (base64 encoded)
              'timestamp': timestamp,
              'postOwnerID': widget.postOwnerID, // Store post owner ID
            })
            .then((docRef) async {
              print("Comment added with ID: ${docRef.id}");

              // Increment the comment count for the post
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.postOwnerID)
                  .collection('posts')
                  .doc(widget.postID)
                  .update({
                    'commentsCount': FieldValue.increment(
                      1,
                    ), // Increment comment count
                  });
            })
            .catchError((e) {
              print("Error adding comment: $e");
            });

        _commentController
            .clear(); // Clear the text field after submitting the comment
        _fetchComments(); // Refresh the comment list
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
      return AssetImage(
        'assets/images/default_profile.png',
      ); // Return a default image if empty
    }
    try {
      Uint8List bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      print('Error decoding base64 image: $e');
      return AssetImage(
        'assets/images/default_profile.png',
      ); // Return default image if error occurs
    }
  }

  // Delete a comment (only the comment creator can delete it)
  Future<void> _deleteComment(String commentID) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Find the comment and check if it's the current user's comment
        DocumentSnapshot commentSnapshot =
            await FirebaseFirestore.instance
                .collection('users') // Users collection
                .doc(widget.postOwnerID) // Post owner
                .collection('posts') // Posts sub-collection
                .doc(widget.postID) // Specific post
                .collection('comments') // Comments sub-collection
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
      appBar: AppBar(
        title: Text(
          "Comment",
          style: GoogleFonts.comicNeue(
            fontSize: 30,
            fontWeight:
                FontWeight.w700, // Replace with your desired font family
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
      ),
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
                    title: Text(
                      comment['username'],
                      style: GoogleFonts.montserrat(
                        fontSize: 18, // Font size for the username
                        fontWeight: FontWeight.w700, // Bold style for the username
                        color: Colors.black, // Text color for the username
                      ),
                    ),
                    subtitle: Text(
                      comment['comment'],
                      style: GoogleFonts.lato(
                        fontSize: 16, // Font size for the comment
                        fontWeight: FontWeight.normal, // Normal style for the comment
                        color: Colors.black87, // Text color for the comment
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Format the timestamp to show date and time in 12-hour format with AM/PM
                        Text(
                          DateFormat('M/d/yyyy hh:mm a').format(
                            (comment['timestamp'] as Timestamp).toDate(),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 10), // Space between timestamp and delete icon
                        // Only show the delete button if the current user is the commenter
                        if (comment['userID'] == FirebaseAuth.instance.currentUser?.uid)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Show confirmation dialog before deleting
                              _showDeleteConfirmationDialog(
                                context,
                                comment['commentID'],
                              );
                            },
                          ),
                      ],
                    ),
                    onTap: () {},
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
                  labelStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black, // Black color for the label
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2,
                    ), // Default border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                maxLines: 3,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addComment,
              style: ElevatedButton.styleFrom(
                fixedSize: Size(MediaQuery.of(context).size.width * 0.7, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Colors.orange,
              ),
              child: Text(
                'Add Comment',
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
    );
  }
}
