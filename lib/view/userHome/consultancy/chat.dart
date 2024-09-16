import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String senderId;
  final String receiverId;

  const ChatPage({required this.senderId, required this.receiverId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _chatCollection =
  FirebaseFirestore.instance.collection('chats');

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    _chatCollection.add({
      'message': _controller.text,
      'senderId': widget.senderId,
      'receiverId': widget.receiverId,
      'timestamp': FieldValue.serverTimestamp(),
      'participants': [widget.senderId, widget.receiverId], // Add participants field
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Live Chat'),
        backgroundColor: const Color(0xff00adb5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _chatCollection
                    .where('participants', arrayContains: widget.senderId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs.where((message) {
                    return message['participants'].contains(widget.receiverId);
                  }).toList();

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      return ChatBubble(
                        message: message['message'],
                        isMe: message['senderId'] == widget.senderId,
                      );
                    },
                  );
                },
              ),
            ),
            ChatInputField(
              controller: _controller,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const ChatBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xff00adb5) : Colors.grey[300],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputField({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send, color: Color(0xff00adb5)),
          ),
        ],
      ),
    );
  }
}
