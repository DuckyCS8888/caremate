import 'package:flutter/material.dart';
import 'package:projects/screen/login.dart';
import 'package:projects/screen/signup.dart';
import '../home.dart'; // Make sure you have the correct import for CommunityScreen
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculate screen width for equal button width
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Ensures vertical centering
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Ensures horizontal centering
              children: [
                // Logo
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/images/caremate.png'
                      ), // Replace with your logo path
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ), // Space between the logo and the welcome text
                // Welcome Text
                Text(
                  'Welcome to Caremate',
                  style: GoogleFonts.comicNeue(
                    fontSize: 40,
                    fontWeight: FontWeight.w900, // Replace with your desired font family
                    color: Colors.black,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ), // Space between the welcome text and buttons
                // Login Button (Above)
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the login screen (or CommunityScreen for now)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(
                      screenWidth * 0.7, 45,
                    ), // Make the button width 80% of screen width, height 50
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.orange, // Button color
                    foregroundColor: Colors.black, // Text color
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.comicNeue(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 15), // Space between the buttons
                // Sign Up Button (Below)
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the signup screen (or CommunityScreen for now)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(
                      screenWidth * 0.7, 45,
                    ), // Make the button width 80% of screen width, height 50
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.orange, // Button color
                    foregroundColor: Colors.black, // Text color
                  ),
                  child: Text(
                    'Sign Up',
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
        ),
      ),
    );
  }
}
