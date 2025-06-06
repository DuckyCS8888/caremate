import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:projects/profile/profilepage.dart';
import 'package:projects/screen/login.dart';
import 'package:projects/screen/signup.dart';
import 'firebase_options.dart';
import 'help_forum/help_request.dart';
import 'home.dart';
import 'screen/welcome_screen.dart';
import 'calendar/CalendarScreenState.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),  // Directly start with MainPage
    );
  }
}




