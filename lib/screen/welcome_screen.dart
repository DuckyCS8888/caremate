import 'package:flutter/material.dart';
import '../home.dart';  // Make sure you have the correct import for CommunityScreen

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/image/caremate.png'), // Replace with your logo path
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 40), // Space between logo and buttons

              // Login Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to the login screen (or CommunityScreen for now)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CommunityScreen()),
                  );
                },
                child: const Text('Login'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.orange, // Use backgroundColor instead of primary
                ),
              ),
              const SizedBox(height: 20), // Space between buttons

              // Sign Up Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to the signup screen (or CommunityScreen for now)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CommunityScreen()), // Replace with actual SignUp screen
                  );
                },
                child: const Text('Sign Up'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.orange, // Use backgroundColor instead of primary
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
