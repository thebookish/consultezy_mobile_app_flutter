import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ServicesSection extends StatefulWidget {
  const ServicesSection({Key? key}) : super(key: key);

  @override
  _ServicesSectionState createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<ServicesSection> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _serviceDescriptionController = TextEditingController();
  String? _serviceImageUrl;
  bool _isLoading = false;

  Future<void> _addService() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Upload image to Firebase Storage
        String imageUrl = '';
        if (_serviceImageUrl != null) {
          final storageRef = FirebaseStorage.instance.ref().child('serviceImages/${DateTime.now().millisecondsSinceEpoch}');
          await storageRef.putFile(File(_serviceImageUrl!));
          imageUrl = await storageRef.getDownloadURL();
        }

        // Add service to Firestore
        await FirebaseFirestore.instance.collection('consultancies').doc(user.uid).collection('services').add({
          'serviceName': _serviceNameController.text,
          'serviceDescription': _serviceDescriptionController.text,
          'serviceImageUrl': imageUrl,
        });

        setState(() {
          _serviceNameController.clear();
          _serviceDescriptionController.clear();
          _serviceImageUrl = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickServiceImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _serviceImageUrl = pickedFile.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('consultancies')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('services')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text('No services available');
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                return ServiceCard(
                  serviceId: doc.id,
                  serviceName: doc['serviceName'],
                  serviceDescription: doc['serviceDescription'],
                  serviceImageUrl: doc['serviceImageUrl'],
                );
              }).toList(),
            );
          },
        ),
        Card(
          elevation: 4,
          surfaceTintColor: Color(0xff00adb5),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _serviceNameController,
                    decoration: InputDecoration(labelText: 'Service Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a service name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _serviceDescriptionController,
                    decoration: InputDecoration(labelText: 'Service Description'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a service description';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickServiceImage,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        image: _serviceImageUrl != null
                            ? DecorationImage(
                          image: FileImage(File(_serviceImageUrl!)),
                          fit: BoxFit.cover,
                        )
                            : null,
                        color: Colors.grey[200],
                      ),
                      child: _serviceImageUrl == null
                          ? Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey))
                          : null,
                    ),
                  ),
                  SizedBox(height: 16),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(

                    onPressed: _addService,
                    child: Text('Add Service', style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(
                      primary: const Color(0xff00adb5),
                    ),)
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String serviceId;
  final String serviceName;
  final String serviceDescription;
  final String serviceImageUrl;

  const ServiceCard({
    Key? key,
    required this.serviceId,
    required this.serviceName,
    required this.serviceDescription,
    required this.serviceImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: Colors.white,
      shadowColor: Color(0xff00adb5),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (serviceImageUrl.isNotEmpty)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(serviceImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            SizedBox(height: 8),
            Text(
              serviceName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              serviceDescription,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
