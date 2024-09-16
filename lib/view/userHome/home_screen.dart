// ignore_for_file: prefer_const_constructors, must_be_immutable, unnecessary_cast, use_build_context_synchronously, no_leading_underscores_for_local_identifiers, sort_child_properties_last, avoid_print

import 'package:consultezy/auth/login.dart';
import 'package:consultezy/auth/student_registration.dart';
import 'package:consultezy/view/userHome/community_screen.dart';
import 'package:consultezy/view/userHome/consultancy/main_screen.dart';
import 'package:consultezy/view/userHome/notification_screen.dart';
import 'package:consultezy/view/userHome/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({
    Key? key,
  }) : super(key: key);

  List<Widget> navpages = [
    HomePage(),
    CommunityPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentIndexProvider);

    final unreadNotificationsCount = ref.watch(unreadNotificationsProvider);
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
        final email = userData['email'] ?? '';
        final profilePicture = userData['profilePicture'] ?? '';
        final userName = userData['name'] ?? '';
        bool isApproved = userData['approved'] ?? false;
        final userId = userData['userId'].toString();
        return WillPopScope(
          onWillPop: () async {
            if (currentIndex == 0) {
              // If the current index is 0 (first index),
              // do not allow the back button to pop the screen
              return false;
            } else {
              // Otherwise, navigate to the previous index
              ref.read(currentIndexProvider.state).state = currentIndex - 1;
              return false;
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Center(
                  child: Text(
                'Hello, $userName!',
                style: TextStyle(color: Color(0xff00adb5)),
              )),
              elevation: 0,
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications,
                        color: Color(0xff00adb5),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationPage(),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadNotificationsCount.when(
                            data: (count) => '$count',
                            loading: () => '',
                            error: (_, __) => '',
                          ),
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(
                color: Color(0xff00adb5),
              ),
            ),
            drawer: Drawer(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(
                      userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    accountEmail: Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    currentAccountPicture: CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xff00adb5),
                      backgroundImage: (profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
                              as ImageProvider<Object>
                          : AssetImage('assets/images/logo.png')
                              as ImageProvider<Object>),
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xff00adb5),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.report_problem,
                      color: Color.fromARGB(255, 209, 212, 17),
                    ),
                    title: Text('Report'),
                    onTap: () {
                      Navigator.pushNamed(context, '/report');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.info,
                      color: Color(0xff00adb5),
                    ),
                    title: Text('About'),
                    onTap: () {
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    title: Text('Logout'),
                    onTap: () async {
                      final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
                      await _firebaseAuth.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            body: navpages[currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                ref.read(currentIndexProvider.state).state = index;
              },
              selectedItemColor: Color(0xff00adb5),
              unselectedItemColor:
                  Colors.black, // Set unselected item color to black
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.forum),
                  label: 'Community',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void sendReminderForApproval(String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userName = currentUser?.displayName ?? 'N/A';

    try {
      final reminderDocRef =
          FirebaseFirestore.instance.collection('reminder').doc();
      await reminderDocRef.set({
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      print('Error sending reminder: $error');
    }
  }
}

final userProvider = Provider<User?>((ref) {
  final firebaseAuth = FirebaseAuth.instance;
  return firebaseAuth.currentUser;
});

final unreadNotificationsProvider = StreamProvider<int>((ref) {
  final notificationsCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('notifications');
  final query = notificationsCollection.where('isRead', isEqualTo: false);
  return query.snapshots().map((snapshot) => snapshot.size);
});

final currentIndexProvider = StateProvider<int>((ref) => 0);
