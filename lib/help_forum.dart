import 'package:flutter/material.dart';
import 'help_request.dart';
import 'home.dart';
import 'volunteer_request.dart';

class HelpForumPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help Forum',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
            ); // Navigate to MainPage
          },
        ),
      ),
      body: SingleChildScrollView( // Allow the content to scroll
        child: Center( // Centering the content
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Align vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Align horizontally
            children: <Widget>[
              SizedBox(height: 50),
              // Help button with bigger size
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 40.0), backgroundColor: Colors.blueAccent, // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // Rounded corners
                  ),
                  fixedSize: Size(300, 220), // Fixed size for both buttons
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HelpRequestPage()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/help.png', // Use help image
                      width: 100.0,
                      height: 100.0,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Help',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50), // Space between buttons
              // Volunteer button with same size as Help button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 40.0), backgroundColor: Colors.orangeAccent, // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // Rounded corners
                  ),
                  fixedSize: Size(300, 220), // Fixed size for both buttons
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VolunteerRequestPage()),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/volunteer.png', // Use volunteer image
                      width: 100.0,
                      height: 100.0,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Volunteer',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


