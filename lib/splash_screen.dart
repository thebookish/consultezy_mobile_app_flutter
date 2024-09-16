// ignore_for_file: library_private_types_in_public_api

import 'package:consultezy/auth/login.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLoginScreen();
  }

  void _navigateToLoginScreen() {
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 300,
              height: 300,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[300],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xff00adb5)),
            ),
          ),
        ],
      ),
    );
  }
}
