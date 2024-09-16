// ignore_for_file: unnecessary_cast, prefer_const_constructors, library_private_types_in_public_api, deprecated_member_use, prefer_const_literals_to_create_immutables, prefer_interpolation_to_compose_strings, empty_catches, sort_child_properties_last, avoid_print, use_key_in_widget_constructors

import 'package:consultezy/view/userHome/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';

import '../../../../component/button.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;

  Future<void> _selectImage() async {
    final pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      final storageRef = FirebaseStorage.instance.ref().child(
          'profilePictures/${DateTime.now().millisecondsSinceEpoch}.jpg');

      try {
        final uploadTask = storageRef.putFile(_image!);
        final snapshot = await uploadTask.whenComplete(() {});
        if (snapshot.state == TaskState.success) {
          final downloadUrl = await snapshot.ref.getDownloadURL();

          final uid = FirebaseAuth.instance.currentUser!.uid;
          final userRef =
              FirebaseFirestore.instance.collection('users').doc(uid);
          await userRef.update({'profilePicture': downloadUrl});
        }
      } catch (error) {
        print('Error uploading image: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final username = userData['name'] ?? 'N/A';

        final mobile = userData['phone'] ?? 'N/A';
        final profilePicture = userData['profilePicture'] ?? '';

        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _selectImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 64,
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xff00adb5),
                            backgroundImage: _image != null
                                ? FileImage(_image!) as ImageProvider<Object>
                                : profilePicture.isNotEmpty
                                    ? NetworkImage(profilePicture)
                                        as ImageProvider<Object>
                                    : AssetImage('assets/images/logo.png')
                                        as ImageProvider<Object>,
                          ),
                          IconButton(
                            onPressed: _selectImage,
                            icon: Icon(
                              Icons.camera_alt,
                              color: Color(0xff00adb5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      username,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff00adb5),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone,
                          color: Color(0xff00adb5),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Mobile:',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff00adb5),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      mobile,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(height: 20),
                    Button(
                      text: 'Settings',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => EditProfilePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
