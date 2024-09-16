import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:consultezy/view/consultancy_home/chatDetails.dart';
import 'package:flutter/material.dart';

class ConsultancyUserListPage extends StatefulWidget {
  final String consultancyId;

  const ConsultancyUserListPage({required this.consultancyId});

  @override
  _ConsultancyUserListPageState createState() => _ConsultancyUserListPageState();
}

class _ConsultancyUserListPageState extends State<ConsultancyUserListPage> {
  final CollectionReference _chatCollection = FirebaseFirestore.instance.collection('chats');
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<String> _getUsername(String senderId) async {
    try {
      final userDoc = await _usersCollection.doc(senderId).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc['name'] ?? 'Unknown User';
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
    return 'Unknown User'; // Fallback if username is not found
  }

  Future<String?> _getProfileImageUrl(String senderId) async {
    try {
      final userDoc = await _usersCollection.doc(senderId).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc['profilePicture']; // Assuming you have profile image URLs stored
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
    return null; // Fallback if no profile image is found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   centerTitle: true,
      //   title: const Text('Users Who Messaged'),
      //   backgroundColor: const Color(0xff00adb5),
      // ),
      body: StreamBuilder(
        stream: _chatCollection
            .where('receiverId', isEqualTo: widget.consultancyId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data!.docs;

          // Create a Set to hold unique senderIds
          final Set<String> uniqueUserIds = {};
          final List<DocumentSnapshot> sortedMessages = [];

          // Sort messages by timestamp and collect unique userIds
          for (var message in messages) {
            final senderId = message['senderId'];
            if (!uniqueUserIds.contains(senderId)) {
              uniqueUserIds.add(senderId);
              sortedMessages.add(message);
            }
          }

          return ListView.builder(
            itemCount: uniqueUserIds.length,
            itemBuilder: (context, index) {
              final senderId = uniqueUserIds.elementAt(index);
              final message = sortedMessages.firstWhere((msg) => msg['senderId'] == senderId);

              return FutureBuilder(
                future: Future.wait([
                  _getUsername(senderId),      // Fetch username
                  _getProfileImageUrl(senderId) // Fetch profile image URL
                ]),
                builder: (context, AsyncSnapshot<List> userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                      subtitle: Text('Fetching user data...'),
                    );
                  }

                  if (userSnapshot.hasError) {
                    return const ListTile(
                      title: Text('Error loading user'),
                      subtitle: Text('Please try again later'),
                    );
                  }

                  final username = userSnapshot.data![0] as String; // Username
                  final profileImageUrl = userSnapshot.data![1] as String?; // Profile image URL

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person), // Fallback to default image
                      radius: 24,
                    ),
                    title: Text(
                      username, // Display username fetched from Firestore
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Last message: ${message['message']}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatTimestamp(message['timestamp']), // Format timestamp
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            senderId: widget.consultancyId,
                            receiverId: senderId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute}'; // Format as HH:MM or customize further
  }
}
