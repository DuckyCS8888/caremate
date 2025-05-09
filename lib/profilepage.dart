import 'package:flutter/material.dart';
import 'edit_profile.dart'; // Edit profile page

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 0; // Keeps track of the current selected tab
  List<bool> _isFollowingSuggestedFriends = List.generate(7, (index) => false);

  // Dummy list of followers (for now, stock data)
  final List<Map<String, String>> _followers = [
    {"name": "ir_amin_uk", "username": "amin"},
    {"name": "tunnel4343", "username": "Azuin"},
    {"name": "ayumisani", "username": "阿乌米"},
    {"name": "norni_armiza_yunus", "username": "Norni Armiza Yunus"},
    {"name": "emma.capybarra2", "username": "Emma"},
  ];

  // Dummy list of people the user follows
  final List<Map<String, String>> _following = [
    {"name": "john_doe", "username": "JohnDoe123"},
    {"name": "jane_smith", "username": "Jane_Smith"},
    {"name": "bob_brown", "username": "Bob_Brown"},
    {"name": "alice_williams", "username": "AliceW"},
    {"name": "mike_jones", "username": "MikeJones"},
  ];

  // Dummy data for suggested friends
  final List<Map<String, String>> _suggestedFriends = [
    {"name": "trentarnold66", "username": "Trent Alexander-Arnold"},
    {"name": "paucubarsi", "username": "paucubarsi"},
    {"name": "mosalah", "username": "Mohamed Salah"},
    {"name": "alejandrobald", "username": "ALEJANDRO BALDE"},
    {"name": "mancity", "username": "Manchester City"},
    {"name": "beinsports", "username": "beIN SPORTS"},
    {"name": "fifaworldcup", "username": "FIFA World Cup"},
  ];

  // Simulating the "Following" state with a List of booleans for followers and following
  List<bool> _isFollowingFollowers = List.generate(5, (index) => false); // Followers: Initially "Follow"
  List<bool> _isFollowingFollowing = List.generate(5, (index) => true);  // Following: Initially "Following"

  // Method to show Followers list as a dialog
  void _showFollowers() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),  // Rounded corners for the dialog
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Ensures the dialog height is dynamic
              children: [
                // Dialog header with "Followers" title and "X" button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Followers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.black),  // "X" button
                      onPressed: () {
                        Navigator.of(context).pop();  // Close the dialog
                      },
                    ),
                  ],
                ),
                Divider(),  // Divider line to separate the title from the list
                // Followers List
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 300), // Max height for dialog
                  child: ListView.builder(
                    shrinkWrap: true, // Allows resizing based on content
                    itemCount: _followers.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person),
                        ),
                        title: Text(_followers[index]["name"]!),
                        subtitle: Text('@${_followers[index]["username"]}'),
                        trailing: ElevatedButton(
                          onPressed: () {},  // "Follow" button for followers
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,  // Text color
                            backgroundColor: Colors.orange,  // Button background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),  // Button shape
                            ),
                          ),
                          child: Text("Follow"),  // Always show "Follow" for followers
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to show Following list as a dialog
  void _showFollowing() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),  // Rounded corners for the dialog
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Ensures the dialog height is dynamic
              children: [
                // Dialog header with "Following" title and "X" button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Following', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.black),  // "X" button
                      onPressed: () {
                        Navigator.of(context).pop();  // Close the dialog
                      },
                    ),
                  ],
                ),
                Divider(),  // Divider line to separate the title from the list
                // Following List
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 300), // Max height for dialog
                  child: ListView.builder(
                    shrinkWrap: true, // Allows resizing based on content
                    itemCount: _following.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person),
                        ),
                        title: Text(_following[index]["name"]!),
                        subtitle: Text('@${_following[index]["username"]}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isFollowingFollowing[index] = !_isFollowingFollowing[index];  // Toggle follow state
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,  // Text color
                            backgroundColor: _isFollowingFollowing[index] ? Colors.grey : Colors.orange,  // Button background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),  // Button shape
                            ),
                          ),
                          child: Text(_isFollowingFollowing[index] ? "Following" : "Follow"),  // Change text based on state
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to show Suggested Users for Add Friends
  void _showSuggestedFriends() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),  // Rounded corners for the dialog
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Suggested for You', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.black),  // Close button
                      onPressed: () {
                        Navigator.of(context).pop();  // Close the dialog
                      },
                    ),
                  ],
                ),
                Divider(),  // Divider line to separate the title from the list
                // Suggested Friends List
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 300), // Max height for dialog
                  child: ListView.builder(
                    shrinkWrap: true,  // Allows resizing based on content
                    itemCount: _suggestedFriends.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person),
                        ),
                        title: Text(_suggestedFriends[index]["username"]!),
                        subtitle: Text('@${_suggestedFriends[index]["name"]!}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isFollowingSuggestedFriends[index] = !_isFollowingSuggestedFriends[index];  // Toggle follow state
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: _isFollowingSuggestedFriends[index] ? Colors.grey : Colors.orange,  // Change background color based on follow state
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),  // Button shape
                            ),
                          ),
                          child: Text(_isFollowingSuggestedFriends[index] ? "Following" : "Follow"),  // Change text based on state
                        ),
                      );
                    },
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
        title: Text("Profile Page", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              ),
              SizedBox(height: 10),

              // Name and Role
              Text(
                'Ibrahim bin Saiful',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'NGO Worker',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),

              // Bio
              Text(
                'Just a guy trying to make the world a better place',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text('6', style: TextStyle(fontSize: 18)),
                      Text('Posts', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showFollowers,  // Show followers when tapped
                    child: Column(
                      children: [
                        Text('5', style: TextStyle(fontSize: 18)),
                        Text('Followers', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showFollowing,  // Show following when tapped
                    child: Column(
                      children: [
                        Text('5', style: TextStyle(fontSize: 18)),
                        Text('Following', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfilePage()),  // Navigate to EditProfilePage
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Edit Profile'),
                  ),
                  ElevatedButton(
                    onPressed: _showSuggestedFriends,  // Show suggested friends on button press
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Add Friends'),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Photos Grid
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,  // 3 photos per row
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://via.placeholder.com/150',
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

void main() {
  runApp(MaterialApp(
    home: ProfilePage(),  // ProfilePage as the home page
  ));
}
