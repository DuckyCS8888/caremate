import 'dart:core';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'calendar/CalendarScreenState.dart';
import 'community/community.dart';
import 'first_aid/first_aid.dart';
import 'help_forum/help_forum.dart';
import 'profile/profilepage.dart';

class MainPage extends StatefulWidget {
  final int selectedIndex;  // Accept selectedIndex from other pages (default is 0)

  const MainPage({super.key, this.selectedIndex = 0});  // Default to 0 for CommunityPage

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex;  // Track selected navigation item

  // Define the list of pages to navigate to
  static final List<Widget> _pages = <Widget>[
    CommunityForum(),       // Community page
    CalendarScreen(),       // Calendar page
    FirstAidPage(),         // First Aid page
    HelpForumPage(),      // Help Request page
    ProfilePage(),          // Profile page
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;  // Set selectedIndex from the passed value
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;  // Update the selected page
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],  // Display selected page
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: _selectedIndex == 0
                ? Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                  Icons.group,
                  color: Colors.white,
                  size: 23),
            )
                : Icon(Icons.group,
                color: Colors.grey,
                size: 20),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 1
                ? Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 23),
            )
                : Icon(Icons.calendar_today,
                color: Colors.grey,
                size: 20),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 2
                ? Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                  Icons.medical_services,
                  color: Colors.white,
                  size: 45),
            )
                : Icon(
                Icons.medical_services,
                color: Colors.red,
                size: 45),
            label: 'First Aid',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 3
                ? Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepOrange,  // Selected background red
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                  Icons.help,
                  color: Colors.white,
                  size: 23),
            )
                : Icon(Icons.help,
                color: Colors.grey,
                size: 20),
            label: 'Help Request',
          ),
          BottomNavigationBarItem(
            icon: _selectedIndex == 4
                ? Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 23),
            )
                : Icon(Icons.person,
                color: Colors.grey,
                size: 20),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,  // Set selected item color to white
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.transparent,  // Remove background color to keep container background visible
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,  // Handle item taps
      ),
    );
  }
}
