// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> fetchAndStoreNotifications() async {
    final houseOwnerNotifications = await FirebaseFirestore.instance
        .collection('house_owner_notifications')
        .get();

    for (var doc in houseOwnerNotifications.docs) {
      final notificationData = doc.data();
      final title = notificationData['title'] as String;
      final subtitle = notificationData['subtitle'] as String;
      final date = notificationData['date'] as String;

      // Check if a notification with the same data already exists in the user's collection
      final existingNotification = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('title', isEqualTo: title)
          .where('subtitle', isEqualTo: subtitle)
          .where('date', isEqualTo: date)
          .get();

      if (existingNotification.docs.isEmpty) {
        final notification = {
          'title': title,
          'subtitle': subtitle,
          'date': date,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add(notification);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAndStoreNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff00adb5),
        title: Text('Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!.docs;

            if (notifications.isEmpty) {
              return Center(child: Text('No notifications available.'));
            }

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notificationData =
                    notifications[index].data() as Map<String, dynamic>;
                final title = notificationData['title'] as String;
                final subtitle = notificationData['subtitle'] as String;
                final date = notificationData['date'] as String;
                final isRead = notificationData['isRead'] as bool;

                return NotificationCard(
                  title: title,
                  subtitle: subtitle,
                  date: date,
                  isRead: isRead,
                  onMarkAsRead: () {
                    // Mark notification as read and navigate to details page if needed
                    if (!isRead) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('notifications')
                          .doc(notifications[index].id)
                          .update({'isRead': true});
                      // Add navigation code here
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final bool isRead;
  final VoidCallback onMarkAsRead;

  const NotificationCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.date,
    this.isRead = false,
    required this.onMarkAsRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: isRead ? Colors.white : Color.fromARGB(255, 209, 240, 242),
      child: ListTile(
        onTap: onMarkAsRead,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isRead ? Colors.black : Color(0xff00adb5),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isRead ? Colors.black87 : Color(0xff00adb5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: $date',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isRead ? Colors.black54 : Color(0xff00adb5),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.circle,
          color: isRead ? Colors.grey : Color(0xff00adb5),
          size: 12,
        ),
      ),
    );
  }
}
