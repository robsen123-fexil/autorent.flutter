import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Bookingrequest extends StatefulWidget {
  const Bookingrequest({super.key});

  @override
  _BookingrequestState createState() => _BookingrequestState();
}

class _BookingrequestState extends State<Bookingrequest> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔁 Listen to real-time bookings
  Stream<QuerySnapshot> getBookingRequests() {
    return _firestore.collection('bookings').snapshots();
  }

  /// ✅ Approve booking: move to reserved & mark vehicle as unavailable
  Future<void> approveBooking(
    String bookingId,
    Map<String, dynamic> bookingData,
  ) async {
    try {
      // Add to 'reserved' collection
      await _firestore.collection('reserved').add(bookingData);

      // Delete from 'bookings' collection
      await _firestore.collection('bookings').doc(bookingId).delete();

      // Update vehicle status to "Unavailable"
      await _firestore
          .collection('vehicles')
          .doc(bookingData['vehicleId'])
          .update({'status': 'Unavailable'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking approved and reserved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving booking: $e')));
    }
  }

  /// ❌ Reject booking: just remove it from 'bookings'
  Future<void> rejectBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking rejected.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting booking: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Booking Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getBookingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No booking requests.'));
          }

          final bookingDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookingDocs.length,
            itemBuilder: (context, index) {
              final booking = bookingDocs[index].data() as Map<String, dynamic>;
              final bookingId = bookingDocs[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (booking['imageUrl'] != null)
                            Image.network(
                              booking['imageUrl'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['vehicleName'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ETB ${booking['rate'] ?? 'N/A'} /day',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                                Text(
                                  'User: ${booking['userEmail'] ?? 'N/A'}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pickup: ${booking['pickupDate']} at ${booking['pickupTime']}',
                                ),
                                Text(
                                  'Return: ${booking['returnDate']} at ${booking['returnTime']}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => approveBooking(bookingId, booking),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => rejectBooking(bookingId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Reject'),
                          ),
                        ],
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
