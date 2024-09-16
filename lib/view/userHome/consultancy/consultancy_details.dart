import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consultezy/component/button.dart';
import 'package:consultezy/view/userHome/consultancy/component/appointment.dart';
import 'package:consultezy/view/userHome/consultancy/component/customer_revieiw.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat.dart';

class ConsultancyDetailsPage extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String description;
  final String id;

  ConsultancyDetailsPage({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.description, required this.id,
  }) : super(key: key);

  Future<List<Service>> fetchServices() async {
    final servicesSnapshot = await FirebaseFirestore.instance
        .collection('consultancies')
        .doc(id)
        .collection('services')
        .get();

    return servicesSnapshot.docs.map((doc) {
      return Service(
        serviceName: doc['serviceName'],
        serviceDescription: doc['serviceDescription'],
        serviceImageUrl: doc['serviceImageUrl'],
      );
    }).toList();
  }
  User? currentUser = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(name),
          backgroundColor: Color(0xff00adb5),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 200, // Adjust height as needed
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consultancy Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    // Add appointment booking section
                   AppointmentBookingSection(consultancyId: id,),
                    const SizedBox(height: 16),
              // Add services section
              FutureBuilder<List<Service>>(
                future: fetchServices(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return const Text('Error loading services');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No services available');
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Services',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: snapshot.data!.map((service) {
                            return ServiceCard(service: service);
                          }).toList(),
                        ),
                      ],
                    );
                  }
                },
              ),
                    // Add customer reviews section
                     CustomerReviewsSection(consultancyId: id,),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xff00adb5),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatPage(senderId: currentUser!.uid, receiverId: id,)),
            );
          },
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }
}

class Service {
  final String serviceName;
  final String serviceDescription;
  final String serviceImageUrl;

  Service({
    required this.serviceName,
    required this.serviceDescription,
    required this.serviceImageUrl,
  });
}

class ServiceCard extends StatelessWidget {
  final Service service;

  const ServiceCard({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(service.serviceImageUrl),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(8.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.serviceName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  service.serviceDescription,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
