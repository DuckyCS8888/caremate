import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:projects/home.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/screen/welcome_screen.dart';

void main() async {
//TODO - Insert initialisation of Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp( const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Disable the debug banner
      theme: ThemeData(
        primarySwatch: Colors.orange, // You can change the primary color if needed
      ),
      home: const WelcomeScreen(), // Set WelcomeScreen as the home screen
    );
  }
}