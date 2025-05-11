import 'dart:convert'; // For base64Decode
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart'; // Flutter Material UI
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for storing and retrieving data
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication for user authentication
import 'package:google_fonts/google_fonts.dart'; // Google Fonts for styling text

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();  // Fetch notifications when the page is initialized
  }

  //
  Future<void> _fetchNotifications() async {
    try {
      FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((querySnapshot) {
        List<Map<String, dynamic>> notifications = [];
        bool hasUnread = false;
        for (var doc in querySnapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          notifications.add(data);

          // 检查是否有未读通知
          if (data['isRead'] == false) {
            hasUnread = true;
          }
        }

        setState(() {
          _notifications = notifications;
          _hasUnreadNotifications = hasUnread;
        });
      });
    } catch (e) {
      print("Error fetching notifications: $e");
    }
  }


  Future<void> _createNotification(String postId, String type) async {
    try {
      FirebaseFirestore.instance.collection('notifications').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'postId': postId,
        'type': type,  // 'like' or 'comment'
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false, // Mark as unread initially
      });
    } catch (e) {
      print("Error creating notification: $e");
    }
  }



  // Mark notifications as read when user taps on them
  Future<void> _markNotificationsAsRead() async {
    try {
      var batch = FirebaseFirestore.instance.batch();

      for (var notification in _notifications) {
        if (!notification['isRead']) {
          var notificationRef = FirebaseFirestore.instance.collection('notifications').doc(notification['id']);
          batch.update(notificationRef, {'isRead': true});
        }
      }

      await batch.commit();
    } catch (e) {
      print("Error marking notifications as read: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          // Show red dot if there are unread notifications
          _hasUnreadNotifications
              ? Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {},
              ),
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
              : IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
        body: ListView.builder(
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            var notification = _notifications[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(notification['profilePic'] ?? ''),
              ),
              title: Text('${notification['username']}'),
              subtitle: Text(notification['type'] == 'like' ? 'Liked your post' : 'Commented on your post'),
              trailing: Text(
                '${(notification['timestamp'] as Timestamp).toDate()}',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                // Mark as read when the user taps on the notification
                _markNotificationsAsRead();
              },
            );
          },
        )

    );
  }
}
