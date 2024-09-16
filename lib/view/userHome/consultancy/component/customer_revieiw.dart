import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerReviewsSection extends StatefulWidget {
  final String consultancyId;

  const CustomerReviewsSection({Key? key, required this.consultancyId}) : super(key: key);

  @override
  _CustomerReviewsSectionState createState() => _CustomerReviewsSectionState();
}

class _CustomerReviewsSectionState extends State<CustomerReviewsSection> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;

  Future<void> submitReview() async {
    if (_rating > 0 && _reviewController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('consultancies')
          .doc(widget.consultancyId)
          .collection('reviews')
          .add({
        'reviewText': _reviewController.text,
        'rating': _rating,
        'timestamp': Timestamp.now(),
      });
      setState(() {
        _reviewController.clear();
        _rating = 0;
      });
    }
  }

  Future<List<Review>> fetchReviews() async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('consultancies')
        .doc(widget.consultancyId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .get();

    return reviewsSnapshot.docs.map((doc) {
      return Review(
        reviewText: doc['reviewText'],
        rating: doc['rating'],
        timestamp: doc['timestamp'],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8,),
        const Text(
          'Customer Reviews',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Review>>(
          future: fetchReviews(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return const Text('Error loading reviews');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No reviews yet');
            } else {
              return Column(
                children: snapshot.data!.map((review) {
                  return ReviewCard(review: review);
                }).toList(),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Submit Your Review',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Write a review',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Rating:'),
            const SizedBox(width: 8),
            DropdownButton<double>(
              value: _rating,
              items: [0,1, 2, 3, 4, 5]
                  .map((e) => DropdownMenuItem<double>(
                value: e.toDouble(),
                child: Text(e.toString()),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _rating = value!;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: submitReview,
          child: const Text('Submit Review',style: TextStyle(color: Colors.white),),
          style: ElevatedButton.styleFrom(
            primary: const Color(0xff00adb5),
          ),
        ),
      ],
    );
  }
}

class Review {
  final String reviewText;
  final double rating;
  final Timestamp timestamp;

  Review({
    required this.reviewText,
    required this.rating,
    required this.timestamp,
  });
}

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({Key? key, required this.review}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                    (index) => Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(review.reviewText),
            const SizedBox(height: 8),
            Text(
              'Reviewed on: ${getPostTime(review.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
String getPostTime(Timestamp timestamp) {
  final dateTime = timestamp.toDate();
  final timeFormat = DateFormat('hh:mm a, dd-MM-yyyy');
  return timeFormat.format(dateTime);
}