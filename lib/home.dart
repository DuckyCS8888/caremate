import 'dart:core';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'calendar/CalendarScreenState.dart';
import 'community/community.dart';
import 'first_aid/first_aid.dart';
import 'help_request.dart';
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
    HelpRequestPage(),      // Help Request page
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'First Aid',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Help Request',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,  // Handle item taps
      ),
    );
  }
}
