import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in to view bookings.")),
      );
    }

    final bookingsFuture = Future.wait([
      FirebaseFirestore.instance
          .collection('reserved')
          .where('userId', isEqualTo: currentUser.uid)
          .get(),
      FirebaseFirestore.instance
          .collection('returned')
          .where('userId', isEqualTo: currentUser.uid)
          .get(),
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<QuerySnapshot>>(
        future: bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No bookings found."));
          }

          final reservedDocs = snapshot.data![0].docs;
          final returnedDocs = snapshot.data![1].docs;
          final allBookings = [...reservedDocs, ...returnedDocs];

          if (allBookings.isEmpty) {
            return const Center(child: Text("No bookings found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allBookings.length,
            itemBuilder: (context, index) {
              final booking = allBookings[index];
              return BookingCard(booking: booking);
            },
          );
        },
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final QueryDocumentSnapshot booking;

  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final data = booking.data() as Map<String, dynamic>;

    final vehicleName = data['vehicleName'] ?? 'Unknown';
    final vehicleType = data['vehicleType'] ?? 'N/A';
    final pickupDate = (data['pickupDate'] as Timestamp?)?.toDate();
    final returnDate = (data['returnDate'] as Timestamp?)?.toDate();
    final status = data['status'] ?? 'Pending';
    final imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] : null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          if (imageUrl != null && imageUrl is String && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              vehicleName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Type: $vehicleType"),
                  Text(
                    "From: ${pickupDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}",
                  ),
                  Text(
                    "To: ${returnDate?.toLocal().toString().split(' ')[0] ?? 'N/A'}",
                  ),
                  Text("Status: $status"),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'return') {
                  _showReturnDialog(context);
                } else if (value == 'review') {
                  _showReviewDialog(context);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'return',
                      child: Text('Return Vehicle'),
                    ),
                    const PopupMenuItem(
                      value: 'review',
                      child: Text('Add Review'),
                    ),
                  ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final vehicleId = booking['vehicleId'];

    final returnedSnapshot =
        await FirebaseFirestore.instance
            .collection('returned')
            .where('userId', isEqualTo: currentUser.uid)
            .where('vehicleId', isEqualTo: vehicleId)
            .get();

    if (returnedSnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You've already returned this vehicle.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Return Vehicle"),
            content: const Text(
              "Are you sure you want to return this vehicle?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('returned').add({
                    'userId': currentUser.uid,
                    'vehicleId': vehicleId,
                    'vehicleName': booking['vehicleName'],
                    'vehicleType': booking['vehicleType'],
                    'pickupDate': booking['pickupDate'],
                    'returnDate': booking['returnDate'],
                    'returnedAt': Timestamp.now(),
                    'status': null,
                    if ((booking.data() as Map).containsKey('imageUrl'))
                      'imageUrl': booking['imageUrl'],
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Vehicle marked as returned."),
                    ),
                  );
                },
                child: const Text("Confirm"),
              ),
            ],
          ),
    );
  }

  void _showReviewDialog(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final reviewSnapshot =
        await FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: currentUser.uid)
            .where('vehicleId', isEqualTo: booking.id)
            .get();

    if (reviewSnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You've already reviewed this vehicle.")),
      );
      return;
    }

    final TextEditingController reviewController = TextEditingController();
    double rating = 3;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text("Add Review"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: reviewController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Write your review here...",
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text("Rating: ${rating.toStringAsFixed(1)}"),
                      Slider(
                        min: 1,
                        max: 5,
                        divisions: 4,
                        value: rating,
                        label: rating.toString(),
                        onChanged: (value) => setState(() => rating = value),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('reviews')
                            .add({
                              'userId': currentUser.uid,
                              'vehicleId': booking.id,
                              'vehicleName': booking['vehicleName'],
                              'review': reviewController.text.trim(),
                              'rating': rating,
                              'createdAt': Timestamp.now(),
                            });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Review submitted")),
                        );
                      },
                      child: const Text("Submit"),
                    ),
                  ],
                ),
          ),
    );
  }
}
