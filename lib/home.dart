import 'dart:core';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'CalendarScreenState.dart';
import 'community/community.dart';
import 'first_aid.dart';
import 'help_request.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;  // Track selected navigation item

  // Define the list of pages to navigate to
  static List<Widget> _pages = <Widget>[
    CommunityForum(),       // Community page
    CalendarScreen(),       // Calendar page
    FirstAidPage(),         // First Aid page
    HelpRequestPage(),      // Help Request page
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;  // Update the selected page
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("CareMate"),
      ),
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
        selectedItemColor: Colors.red,  // Color for selected item
        unselectedItemColor: Colors.grey,  // Color for unselected items
        onTap: _onItemTapped,  // Handle item taps
      ),
    );
  }
}