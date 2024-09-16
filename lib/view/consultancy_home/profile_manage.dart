import 'package:consultezy/view/consultancy_home/component/appointments.dart';
import 'package:consultezy/view/consultancy_home/component/customer_review.dart';
import 'package:consultezy/view/consultancy_home/component/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ManageConsultancyProfilePage extends StatefulWidget {
  @override
  _ManageConsultancyProfilePageState createState() => _ManageConsultancyProfilePageState();
}

class _ManageConsultancyProfilePageState extends State<ManageConsultancyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;
  bool _isEditingName = false;
  bool _isEditingDescription = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (_user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('consultancies').doc(_user!.uid).get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc['consultancyName'];
          _descriptionController.text = doc['address'];
          _imageUrl = doc['imageUrl'];
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate() && _user != null) {
      setState(() {
        _isLoading = true;
      });

      await FirebaseFirestore.instance.collection('consultancies').doc(_user!.uid).update({
        'consultancyName': _nameController.text,
        'address': _descriptionController.text,
        'imageUrl': _imageUrl,
      });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('consultancyImages/${_user!.uid}');
      await storageRef.putFile(File(pickedFile.path));
      final imageUrl = await storageRef.getDownloadURL();

      // Update imageUrl in Firestore
      setState(() {
        _imageUrl = imageUrl;
      });

      await FirebaseFirestore.instance.collection('consultancies').doc(_user!.uid).update({
        'imageUrl': _imageUrl,
      });

      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required bool isEditing,
    required VoidCallback toggleEditing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                readOnly: !isEditing,
                decoration: InputDecoration(
                  labelText: label,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a $label';
                  }
                  return null;
                },
              ),
            ),
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit),
              onPressed: toggleEditing,
              color: Colors.teal,
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xff00adb5),
        elevation: 0,
        title: Text('Manage Profile', style: TextStyle(color: Color(0xff00adb5))),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Color(0xff00adb5)),
            onPressed: _updateProfile,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: _imageUrl != null
                          ? DecorationImage(
                        image: NetworkImage(_imageUrl!),
                        fit: BoxFit.cover,
                      )
                          : null,
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: _imageUrl == null
                        ? Center(
                      child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                    )
                        : Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                _buildEditableField(
                  controller: _nameController,
                  label: 'Name',
                  isEditing: _isEditingName,
                  toggleEditing: () {
                    setState(() {
                      _isEditingName = !_isEditingName;
                    });
                  },
                ),
                _buildEditableField(
                  controller: _descriptionController,
                  label: 'Description',
                  isEditing: _isEditingDescription,
                  toggleEditing: () {
                    setState(() {
                      _isEditingDescription = !_isEditingDescription;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Appointments'),
                 AppointmentBookingSection(),
                const SizedBox(height: 16),
                _buildSectionTitle('Services'),
                const ServicesSection(),
                const SizedBox(height: 16),
                _buildSectionTitle('Customer Reviews'),
                CustomerReviewsSection(consultancyId: FirebaseAuth.instance.currentUser!.uid,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}


