import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rimarasa/login.dart'; // Import LoginPage
import 'homepage.dart'; // Import Homepage

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextPage();
  }

  // Function to navigate to the next page after a delay
  void _navigateToNextPage() {
    Timer(const Duration(seconds: 3), () {
      // Check if the user is logged in or not
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return const Homepage(); // User is logged in
                  } else {
                    return const LoginPage(); // User is not logged in
                  }
                }
                return const CircularProgressIndicator(); // Loading state
              },
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 241, 224), // Set background color for splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Asset Image
            Image.asset(
              'assets/images/logo.png',
              width: 200, // Set image width (adjust according to your image size)
              height: 200, // Set image height
            ),
            const SizedBox(height: 20),
            // Text under the logo
            const Text(
              'RimaRasa',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Playfair',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
