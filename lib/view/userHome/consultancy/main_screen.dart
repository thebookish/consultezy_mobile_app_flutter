import 'package:consultezy/view/userHome/consultancy/consultancy_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBox(onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            }),
          ),
          Expanded(
            child: ConsultancyList(searchQuery: _searchQuery),
          ),
        ],
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  SearchBox({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by name...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class ConsultancyList extends StatelessWidget {
  final String searchQuery;

  ConsultancyList({required this.searchQuery});

  Future<double> fetchAverageRating(String consultancyId) async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('consultancies')
        .doc(consultancyId)
        .collection('reviews')
        .get();

    if (reviewsSnapshot.docs.isEmpty) return 0.0;

    double totalRating = 0.0;
    reviewsSnapshot.docs.forEach((doc) {
      totalRating += (doc['rating'] as num).toDouble();
    });

    return totalRating / reviewsSnapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('consultancies').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final name = (doc.data() as Map)['consultancyName'].toString().toLowerCase();
          return name.contains(searchQuery);
        }).toList();

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> data = filteredDocs[index].data() as Map<String, dynamic>;

            return FutureBuilder<double>(
              future: fetchAverageRating(filteredDocs[index].id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ConsultancyCard(
                    name: data['consultancyName'] ?? '',
                    rating: 'Loading...',
                    imageUrl: data['imageUrl'] ?? '',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConsultancyDetailsPage(
                            id: filteredDocs[index].id,
                            name: data['consultancyName'] ?? '',
                            description: data['description'] ?? '',
                            imageUrl: data['imageUrl'] ?? '',
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return ConsultancyCard(
                    name: data['consultancyName'] ?? '',
                    rating: 'Error',
                    imageUrl: data['imageUrl'] ?? '',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConsultancyDetailsPage(
                            id: filteredDocs[index].id,
                            name: data['consultancyName'] ?? '',
                            description: data['description'] ?? '',
                            imageUrl: data['imageUrl'] ?? '',
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  final averageRating = snapshot.data!.toStringAsFixed(1);
                  return ConsultancyCard(
                    name: data['consultancyName'] ?? '',
                    rating: averageRating,
                    imageUrl: data['imageUrl'] ?? '',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConsultancyDetailsPage(
                            id: filteredDocs[index].id,
                            name: data['consultancyName'] ?? '',
                            description: data['description'] ?? '',
                            imageUrl: data['imageUrl'] ?? '',
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}



class ConsultancyCard extends StatelessWidget {
  final String name;
  final String rating;
  // final String responseRate;
  final String imageUrl;
  final VoidCallback onPressed;

  ConsultancyCard({
    required this.name,
    required this.rating,
    // required this.responseRate,
    required this.imageUrl,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onPressed,
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                )
                    : Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(child: Icon(Icons.image)),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 4.0),
                        Text(
                          rating,
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ],
                    ),
                    // SizedBox(height: 4.0),
                    // Text(
                    //   'Response Rate: $responseRate%',
                    //   style: TextStyle(fontSize: 14.0),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
