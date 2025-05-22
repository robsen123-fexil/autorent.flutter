import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Vehicle Reviews" , style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 6, 78, 133),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('reviews')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reviews found 😶"));
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final reviewDoc = reviews[index];
              final rating = reviewDoc['rating'] ?? 0;
              final reviewText = reviewDoc['review'] ?? 'No review';
              final vehicleName = reviewDoc['vehicleName'] ?? 'Unknown';
              final timestamp = reviewDoc['createdAt'] as Timestamp;
              final date = DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(timestamp.toDate());

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Text(
                      rating.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    vehicleName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reviewText),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
