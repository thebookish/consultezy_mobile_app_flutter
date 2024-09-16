import 'package:consultezy/auth/login.dart';
import 'package:consultezy/view/consultancy_home/profile_manage.dart';
import 'package:consultezy/view/consultancy_home/support_screen.dart';
import 'package:consultezy/view/userHome/community_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultancyHomeScreen extends StatefulWidget {
  const ConsultancyHomeScreen({Key? key}) : super(key: key);

  @override
  _ConsultancyHomeScreenState createState() => _ConsultancyHomeScreenState();
}

class _ConsultancyHomeScreenState extends State<ConsultancyHomeScreen> {
  late User _currentUser; // Firebase User object
  Map<String, dynamic>? _consultancyData; // Consultancy data from Firestore
  int _selectedIndex = 0; // Bottom navigation bar selected index

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchConsultancyData();
  }

  Future<void> _fetchCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _fetchConsultancyData() async {
    try {
      String userId = _currentUser.uid;
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('consultancies')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _consultancyData = docSnapshot.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error fetching consultancy data: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultancy Home'),
        backgroundColor: const Color(0xff00adb5),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notification icon press
            },
          ),
        ],
      ),
      body: _consultancyData != null
          ? _buildContent()
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support),
            label: 'Support',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xff00adb5),
        onTap: _onItemTapped,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xff00adb5),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageConsultancyProfilePage(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                // Navigate to settings screen
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                FirebaseAuth.instance.signOut();
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
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return ManageConsultancyProfilePage();
      case 1:
        return CommunityPage();
      case 2:
        return ConsultancyUserListPage (consultancyId: _currentUser.uid,);
      default:
        return _buildConsultancyInfo();
    }
  }

  Widget _buildConsultancyInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${_consultancyData!['name']}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Consultancy Details:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text('Address: ${_consultancyData!['address'] ?? 'N/A'}'),
          Text('Phone: ${_consultancyData!['phone'] ?? 'N/A'}'),
          Text('Email: ${_consultancyData!['email'] ?? 'N/A'}'),
          // Add more details as needed
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Implement action for a button, e.g., navigate to a service page
            },
            child: const Text('View Services'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunity() {
    return const Center(
      child: Text(
        'Community Screen',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSupport() {
    return const Center(
      child: Text(
        'Support Screen',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
