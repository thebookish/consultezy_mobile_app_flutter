// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, library_private_types_in_public_api

import 'package:consultezy/component/button.dart';
import 'package:consultezy/component/text_filed.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        if (_profileFormKey.currentState!.validate()) {
          final String newName = _nameController.text;
          final String newPhoneNumber = _phoneNumberController.text;

          if (newName != '') {
            await _firestore.collection('users').doc(user.uid).update({
              'name': newName,
            });
          }
          if (newPhoneNumber != '') {
            await _firestore.collection('users').doc(user.uid).update({
              'phone': newPhoneNumber,
            });
          }

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  'Profile Updated',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff00adb5),
                  ),
                ),
                content: Text('Your profile has been successfully updated.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
              );
            },
          );

          _nameController.clear();
          _phoneNumberController.clear();
        }
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Error!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: Text('Failed to update profile. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
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
          );
        },
      );
    }
  }

  Future<void> _changePassword() async {
    try {
      final User user = _auth.currentUser!;
      final newPassword = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (newPassword == confirmPassword) {
        if (_passwordFormKey.currentState!.validate()) {
          await user.updatePassword(newPassword);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Password Changed',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff00adb5),
                ),
              ),
              content: Text('Your password has been successfully changed.'),
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
          _passwordController.clear();
          _confirmPasswordController.clear();
        }
      } else {
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
            content: Text('Passwords do not match. Please try again.'),
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
          content: Text('Failed to change password. Please try again.'),
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
      appBar: AppBar(
        backgroundColor: Color(0xff00adb5),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Change Name and Phone',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff00adb5),
                ),
              ),
              SizedBox(height: 16),
              Form(
                key: _profileFormKey,
                child: Column(
                  children: [
                    TextFields(
                      controller: _nameController,
                      Labeltext: 'New Name',
                      isObsecure: false,
                    ),
                    SizedBox(height: 16),
                    TextFields(
                      controller: _phoneNumberController,
                      Labeltext: 'New Phone Number',
                      isObsecure: false,
                      validator: (value) {
                        if (value!.isNotEmpty &&
                            !RegExp(r'^[0-9]{11}$').hasMatch(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Button(text: 'Update Profile', onTap: _updateProfile),
              SizedBox(height: 32),
              Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff00adb5),
                ),
              ),
              SizedBox(height: 16),
              Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    TextFields(
                      controller: _passwordController,
                      isObsecure: true,
                      Labeltext: 'New Password',
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
                    SizedBox(height: 16),
                    TextFields(
                      controller: _confirmPasswordController,
                      isObsecure: true,
                      Labeltext: 'Confirm Password',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Button(text: 'Change Password', onTap: _changePassword)
            ],
          ),
        ),
      ),
    );
  }
}
