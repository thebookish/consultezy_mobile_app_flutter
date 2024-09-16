// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors

import 'package:consultezy/auth/login.dart';
import 'package:consultezy/component/button.dart';
import 'package:consultezy/component/text_filed.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late String _selectedCountries;

  final List<String> _countryOptions = [
    'USA',
    'Canada',
    'Australia',
    'UK',
    'Germany',
  ];
  bool isEmailAllowed(String email) {
    final allowedDomains = ['gmail.com', 'yahoo.com', 'outlook.com'];
    final emailDomain = email.split('@').last.toLowerCase();
    return allowedDomains.contains(emailDomain);
  }

  Future<void> registerUser() async {
    try {
      if (_formKey.currentState!.validate()) {
        FirebaseAuth firebaseAuth = FirebaseAuth.instance;
        String email = _emailController.text.trim();
        String password = _confirmPasswordController.text.trim();

        // Check if the email domain is allowed
        if (!isEmailAllowed(email)) {
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
              content: const Text(
                  'Only Gmail, Yahoo, and Outlook domains are allowed for email.'),
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
          return;
        }

        // Create the user account
        final userCredential =
            await firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Send email verification
        await userCredential.user!.sendEmailVerification();
        String userId = userCredential.user!.uid;

        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': email,
          'interested': _selectedCountries,
        });

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Registered!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: const Text('Please verify your email to login.'),
            actions: [
              TextButton(
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff00adb5),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
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
          content: const Text('Something went wrong!'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(),
              ),
            );
          },
        ),
        title: const Text('Student Registration'),
        backgroundColor: const Color(0xff00adb5),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '* Required',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextFields(
                  Labeltext: 'Name',
                  isObsecure: false,
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    // Regex to ensure name doesn't contain numbers
                    if (RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Name cannot contain numbers';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                const Text(
                  '* Required',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextFields(
                  Labeltext: 'Phone Number',
                  isObsecure: false,
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^[0-9]{11}$').hasMatch(value)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                const Text(
                  '* Required',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextFields(
                  Labeltext: 'Email',
                  isObsecure: false,
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFields(
                  Labeltext: 'Password',
                  isObsecure: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password should be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                const SizedBox(height: 8.0),
                TextFields(
                  Labeltext: 'Confirm Password',
                  isObsecure: true,
                  controller: _confirmPasswordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Dropdown field for selecting countries
                const Text(
                  'Select Interested Country:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: null,
                  items: _countryOptions.map((String country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCountries = newValue;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Select country',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xff00adb5)),
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(height: 20),
                Button(text: 'Submit', onTap: registerUser)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
