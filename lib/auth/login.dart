// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, library_private_types_in_public_api, prefer_const_literals_to_create_immutables, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consultezy/auth/consultancy/consultancy_signup.dart';
import 'package:consultezy/auth/student_registration.dart';
import 'package:consultezy/component/button.dart';
import 'package:consultezy/component/text_filed.dart';
import 'package:consultezy/view/consultancy_home/consultancy_home_screen.dart';
import 'package:consultezy/view/userHome/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late SharedPreferences _prefs;
  bool _rememberLogin = false;
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberLogin();
  }

  void updateDeviceToken(String userId) async {
    // Get the device token
    String? deviceToken = await _firebaseMessaging.getToken();

    // Update the device token in the user's document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'deviceToken': deviceToken});
  }

  Future<void> _loadRememberLogin() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberLogin = _prefs.getBool('rememberLogin') ?? false;
      if (_rememberLogin) {
        _emailController.text = _prefs.getString('email') ?? '';
        _passwordController.text = _prefs.getString('password') ?? '';
      }
    });
  }

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      UserCredential userCredential =
      await _firebaseAuth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if the email is verified
      if (!userCredential.user!.emailVerified) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Error!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Text('Please verify your email before logging in.'),
            actions: [
              TextButton(
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff00adb5),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // User successfully logged in
      String userId = userCredential.user!.uid;

      // Check if the user is a consultancy
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('consultancies')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        // User is a consultancy
        // Update device token for consultancy
        updateDeviceToken(userId);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConsultancyHomeScreen(),
          ),
        );
      } else {
        // User is not a consultancy, assume normal user
        // Fetch the user's role from regular users collection
        userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        String username = userSnapshot['name'];
        updateDeviceToken(userId);

        // Normal user, redirect to user home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      }

      // Save login info if remember login is checked
      if (_rememberLogin) {
        _prefs.setString('email', _emailController.text.trim());
        _prefs.setString('password', _passwordController.text.trim());
      } else {
        _prefs.remove('email');
        _prefs.remove('password');
      }
      _prefs.setBool('isLoggedIn', true);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Error!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text('Incorrect Email or Password!'),
          actions: [
            TextButton(
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff00adb5),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
          email: _emailController.text.trim());

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Password Reset Email Sent',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff00adb5),
            ),
          ),
          content: Text('Please check your email to reset your password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff00adb5),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Error!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content:
          Text('Failed to send password reset email. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff00adb5),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff00adb5)),
        ),
      )
          : SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Image.asset('assets/images/logo.png'),
                SizedBox(height: 34),
                TextFields(
                  controller: _emailController,
                  Labeltext: 'Email',
                  isObsecure: false,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff00adb5),
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                      BorderSide(color: Color(0xff00adb5), width: 2.0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: Color(0xff00adb5),
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberLogin,
                      activeColor: Color(0xff00adb5),
                      onChanged: (value) async {
                        setState(() {
                          _rememberLogin = value ?? false;
                        });
                        // Save the remember login preference
                        _prefs.setBool('rememberLogin', _rememberLogin);
                      },
                    ),
                    Text(
                      'Remember me',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w300,
                        color: Color(0xff00adb5),
                        fontFamily: GoogleFonts.poppins().fontFamily,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Button(text: 'Login', onTap: _loginUser),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _resetPassword,
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w300,
                          color: Colors.red,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w300,
                          color: Color(0xff00adb5),
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create account as',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey,
                        fontFamily: GoogleFonts.poppins().fontFamily,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConsultancySignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Consultancy?',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w300,
                          color: Color(0xff00adb5),
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
