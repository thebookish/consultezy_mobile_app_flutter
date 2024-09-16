import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late CollectionReference postsCollection;
  final TextEditingController _postController = TextEditingController();
  File? _imageFile; // Variable to hold the selected image file

  @override
  void initState() {
    super.initState();
    postsCollection = FirebaseFirestore.instance.collection('posts');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: StreamBuilder<QuerySnapshot>(
        stream: postsCollection.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            final posts = snapshot.data!.docs.map((doc) => Post.fromSnapshot(doc)).toList();
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return FutureBuilder<String?>(
                  future: getUserName(post.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasData) {
                      post.userName = snapshot.data!;
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final isCurrentUserOwner = post.userId == currentUser?.uid;
                      return PostWidget(
                        post: post,
                        onCommentPressed: () {
                          showCommentDialog(context, post);
                        },
                        onDeletePressed: () {
                          deletePost(post);
                        },
                        onDeleteCommentPressed: (commentIndex) {
                          deleteComment(post, commentIndex);
                        },
                        isCurrentUserOwner: isCurrentUserOwner,
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error loading username: ${snapshot.error}');
                    } else {
                      return const Text('Username not found');
                    }
                  },
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text('Error fetching posts: ${snapshot.error}');
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff00adb5),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showPostDialog(context);
        },
      ),
    );
  }

  void showPostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newPostText = '';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'New Post',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff00adb5),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_imageFile != null) ...[
                      Image.file(_imageFile!),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton(
                      onPressed: () async {
                        final image = await getImageFromGallery();
                        setState(() {
                          _imageFile = image;
                        });
                      },
                      child: Text(_imageFile == null ? 'Add Image' : 'Change Image'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _postController,
                      onChanged: (value) {
                        newPostText = value;
                      },
                      decoration: const InputDecoration(hintText: 'Enter your post'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (newPostText.isNotEmpty) {
                      final userName = await getUserName(FirebaseAuth.instance.currentUser!.uid);
                      final imageUrl = await uploadImageToFirebaseStorage(_imageFile);

                      await postsCollection.add({
                        'text': newPostText,
                        'timestamp': FieldValue.serverTimestamp(),
                        'comments': [],
                        'userId': FirebaseAuth.instance.currentUser!.uid,
                        'userName': userName,
                        'votes': {'upvotes': 0, 'downvotes': 0},
                        'userVotes': {},
                        'imageUrls': imageUrl != null ? [imageUrl] : [],
                      });
                    }
                    _postController.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Post',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff00adb5),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> uploadImageToFirebaseStorage(File? imageFile) async {
    if (imageFile == null) return null;

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final firebase_storage.Reference ref =
      firebase_storage.FirebaseStorage.instance.ref().child('posts').child(fileName);
      final firebase_storage.UploadTask uploadTask = ref.putFile(imageFile);
      final firebase_storage.TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() => null);
      final String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<File?> getImageFromGallery() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  void showCommentDialog(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newCommentText = '';

        return AlertDialog(
          title: Text(
            'New Comment',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff00adb5),
            ),
          ),
          content: TextField(
            onChanged: (value) {
              newCommentText = value;
            },
            decoration: const InputDecoration(hintText: 'Enter your comment'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (newCommentText.isNotEmpty) {
                  final updatedComments = List<String>.from(post.comments)..add(newCommentText);
                  await postsCollection.doc(post.id).update({'comments': updatedComments});
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'Comment',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff00adb5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void deletePost(Post post) async {
    await postsCollection.doc(post.id).delete();
  }

  void deleteComment(Post post, int commentIndex) async {
    final updatedComments = List<String>.from(post.comments)..removeAt(commentIndex);
    await postsCollection.doc(post.id).update({'comments': updatedComments});
  }

  Future<String> getUserName(String userId) async {
    final consultancySnapshot =
    await FirebaseFirestore.instance.collection('consultancies').doc(userId).get();

    if (consultancySnapshot.exists) {
      final consultancyData = consultancySnapshot.data() as Map<String, dynamic>;
      final consultancyName = consultancyData['consultancyName'] ?? 'Unknown Consultancy';
      return '🧑‍💼 $consultancyName';
    } else {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        final userName = userData['name'] ?? 'Unknown User';
        return userName;
      } else {
        return 'Unknown User';
      }
    }
  }
}

class Post {
  final String id;
  String text;
  final List<String> comments;
  final String userId;
  String userName;
  final Timestamp timestamp;
  Map<String, int> votes;
  Map<String, String> userVotes;
  List<String>? imageUrls; // Optional field for storing image URLs

  Post({
    required this.id,
    required this.text,
    required this.comments,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.votes,
    required this.userVotes,
    this.imageUrls,
  });

  factory Post.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    final text = data['text'] ?? '';
    final comments = List<String>.from(data['comments'] ?? []);
    final userId = data['userId'] ?? '';
    final userName = data['userName'] ?? 'Unknown';
    final timestamp = data['timestamp'] as Timestamp?;
    final votes = Map<String, int>.from(data['votes'] ?? {'upvotes': 0, 'downvotes': 0});
    final userVotes = Map<String, String>.from(data['userVotes'] ?? {});
    final imageUrls = data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : null;

    return Post(
      id: snapshot.id,
      text: text,
      comments: comments,
      userId: userId,
      userName: userName,
      timestamp: timestamp ?? Timestamp.now(),
      votes: votes,
      userVotes: userVotes,
      imageUrls: imageUrls,
    );
  }
}

class PostWidget extends StatefulWidget {
  final Post post;
  final VoidCallback onCommentPressed;
  final VoidCallback onDeletePressed;
  final Function(int) onDeleteCommentPressed;
  final bool isCurrentUserOwner;

  const PostWidget({
    required this.post,
    required this.onCommentPressed,
    required this.onDeletePressed,
    required this.onDeleteCommentPressed,
    required this.isCurrentUserOwner,
  });

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late TextEditingController _editPostController;
  late ValueNotifier<int> _upvotesNotifier;
  late ValueNotifier<int> _downvotesNotifier;
  bool _commentsVisible = false;

  @override
  void initState() {
    super.initState();
    _editPostController = TextEditingController(text: widget.post.text);
    _upvotesNotifier = ValueNotifier(widget.post.votes['upvotes'] ?? 0);
    _downvotesNotifier = ValueNotifier(widget.post.votes['downvotes'] ?? 0);
  }

  @override
  void dispose() {
    _editPostController.dispose();
    _upvotesNotifier.dispose();
    _downvotesNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostHeader(),
            const SizedBox(height: 10),
            Text(widget.post.text, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            if (widget.post.imageUrls != null) ...[
              _buildImages(),
              const SizedBox(height: 10),
            ],
            _buildVoteButtons(),
            const Divider(),
            _buildCommentToggle(),
            if (_commentsVisible) _buildCommentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.post.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff00adb5))),
                Text(
                  getPostTime(widget.post.timestamp),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        if (widget.isCurrentUserOwner) _buildPostOptions(),
      ],
    );
  }

  Widget _buildPostOptions() {
    return PopupMenuButton(
      onSelected: (value) {
        if (value == 'edit') {
          showEditDialog();
        } else if (value == 'delete') {
          widget.onDeletePressed();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  Widget _buildVoteButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildVoteButton('Upvote', _upvotesNotifier, Icons.thumb_up),
        _buildVoteButton('Downvote', _downvotesNotifier, Icons.thumb_down),
      ],
    );
  }

  Widget _buildVoteButton(String label, ValueNotifier<int> countNotifier, IconData icon) {
    return InkWell(
      onTap: () => _voteOnPost(label.toLowerCase(), countNotifier),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 4),
          ValueListenableBuilder<int>(
            valueListenable: countNotifier,
            builder: (context, count, child) {
              return Text('$count', style: TextStyle(color: Colors.grey[600]));
            },
          ),
        ],
      ),
    );
  }

  void _voteOnPost(String voteType, ValueNotifier<int> countNotifier) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userVotes = Map<String, String>.from(widget.post.userVotes);
    final currentVote = userVotes[currentUser.uid];
    final currentVotes = Map<String, int>.from(widget.post.votes);

    if (currentVote != null && currentVote != voteType) {
      if (currentVote == 'upvote' && _upvotesNotifier.value != 0) {
        _upvotesNotifier.value -= 1;
      } else if (currentVote == 'downvote') {
        _downvotesNotifier.value -= 1;
      }
      currentVotes[currentVote] = (currentVotes[currentVote] ?? 0) - 1;
    }
    if (currentVote == voteType) {
      if (voteType == 'upvote' && _upvotesNotifier.value != 0) {
        _upvotesNotifier.value -= 1;
      } else if (voteType == 'downvote') {
        _downvotesNotifier.value -= 1;
      }
      currentVotes[voteType] = (currentVotes[voteType] ?? 0) - 1;
      userVotes.remove(currentUser.uid);
    } else {
      if (voteType == 'upvote') {
        _upvotesNotifier.value += 1;
      } else if (voteType == 'downvote') {
        _downvotesNotifier.value += 1;
      }
      currentVotes[voteType] = (currentVotes[voteType] ?? 0) + 1;
      userVotes[currentUser.uid] = voteType;
    }

    widget.post.votes = currentVotes;
    widget.post.userVotes = userVotes;

    // Update Firestore later
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).update({
    //     'votes': currentVotes,
    //     'userVotes': userVotes,
    //   });
    // });
  }

  Widget _buildCommentToggle() {
    return InkWell(
      onTap: () {
        setState(() {
          _commentsVisible = !_commentsVisible;
        });
      },
      child: Text(
        _commentsVisible ? 'Hide comments' : 'Show comments',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.post.comments.length} Comments', style: const TextStyle(fontWeight: FontWeight.bold)),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.post.comments.length,
          itemBuilder: (context, index) {
            return Row(
              children: [
                Expanded(child: Text(widget.post.comments[index])),
                if (widget.isCurrentUserOwner)
                  IconButton(
                    onPressed: () => widget.onDeleteCommentPressed(index),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  ),
              ],
            );
          },
        ),
        TextButton(
          onPressed: widget.onCommentPressed,
          child: Text('Add a comment', style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }

  Widget _buildImages() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.post.imageUrls!.length,
        itemBuilder: (context, index) {
          final imageUrl = widget.post.imageUrls![index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.network(
              imageUrl,
              width: 150,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  void showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String updatedText = widget.post.text;

        return AlertDialog(
          title: const Text('Edit Post'),
          content: TextField(
            controller: _editPostController,
            onChanged: (value) {
              setState(() {
                updatedText = value;
              });
            },
            decoration: const InputDecoration(hintText: 'Enter your updated post'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (updatedText.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('posts').doc(widget.post.id).update({'text': updatedText});
                  setState(() {
                    widget.post.text = updatedText;
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  String getPostTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final timeFormat = DateFormat('hh:mm a, dd-MM-yyyy');
    return timeFormat.format(dateTime);
  }
}
