import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserFeedbackScreen extends StatelessWidget {
  const UserFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Customer Feedback',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[900],
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
            return const Center(child: Text('No customer feedback yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>?;

              if (data == null) return const SizedBox.shrink();

              return _buildFeedbackCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> data) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    final vehicleName = data['vehicleName'] ?? 'Unknown Vehicle';
    final userName = data['userName'] ?? 'Anonymous';
    final createdAt =
        data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : null;
    final reviewText = data['review'] ?? 'No review text';
    final rating = (data['rating'] is num) ? data['rating'].toInt() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vehicleName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      starIndex < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('By: $userName'),
            if (createdAt != null) Text('On: ${dateFormat.format(createdAt)}'),
            const SizedBox(height: 8),
            Text(
              reviewText,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
