import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReservationHistoryScreen extends StatelessWidget {
  const ReservationHistoryScreen({super.key});

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
          'Reservation History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[900],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('reserved')
                .orderBy('pickupDate', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No reservation history found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _buildReservationCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> data) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final pickupDate = (data['pickupDate'] as Timestamp).toDate();
    final returnDate = (data['returnDate'] as Timestamp).toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['vehicleName'] ?? 'Unknown Vehicle',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('User: ${data['userId']}'),
            Text('Status: ${data['status'] ?? 'Reserved'}'),
            const SizedBox(height: 8),
            Text('Pickup Date: ${dateFormat.format(pickupDate)}'),
            Text('Return Date: ${dateFormat.format(returnDate)}'),
            if (data.containsKey('createdAt'))
              Text(
                'Booked On: ${dateFormat.format((data['createdAt'] as Timestamp).toDate())}',
              ),
          ],
        ),
      ),
    );
  }
}
