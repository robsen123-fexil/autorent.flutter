import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Bookingrequest extends StatefulWidget {
  const Bookingrequest({super.key});

  @override
  _BookingrequestState createState() => _BookingrequestState();
}

class _BookingrequestState extends State<Bookingrequest> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔁 Real-time stream of booking requests
  Stream<QuerySnapshot> getBookingRequests() {
    return _firestore.collection('bookings').snapshots();
  }

  /// 📅 Format a Firestore timestamp to e.g. "Apr 30, 2025 2:45 PM"
  String formatTimestamp(Timestamp ts) {
    final dt = ts.toDate();
    return DateFormat.yMMMd().add_jm().format(dt);
  }
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false, // optional for later filtering
    });
  }

  /// ✅ Approve booking → move to 'reserved', mark vehicle unavailable
Future<void> approveBooking(
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('reserved').add(data);
      await _firestore.collection('bookings').doc(bookingId).delete();
      await _firestore.collection('vehicles').doc(data['vehicleId']).update({
        'status': 'Unavailable',
      });

      // ✅ Send notification
      final pickup = (data['pickupDate'] as Timestamp).toDate();
      final returnDate = (data['returnDate'] as Timestamp).toDate();
      final dateFormat = DateFormat.yMMMd().format;

      await sendNotification(
        userId: data['userId'],
        title: '🎉 Booking Approved!',
        message:
            'Congratulations! Your booking has been approved. You can pick your car on ${dateFormat(pickup)} and return it on ${dateFormat(returnDate)}.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking approved & notification sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving booking: $e')));
    }
  }


  /// ❌ Reject booking → delete & free up vehicle
Future<void> rejectBooking(
    String bookingId,
    String vehicleId,
    String userId,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      await _firestore.collection('vehicles').doc(vehicleId).update({
        'status': 'Available',
      });

      // ❌ Send rejection notification
      await sendNotification(
        userId: userId,
        title: '🚫 Booking Rejected',
        message:
            'Sorry, your booking was not approved. Please review our terms and conditions.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected & user notified.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting booking: $e')));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin – Booking Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getBookingRequests(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No booking requests.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final booking = docs[i].data() as Map<String, dynamic>;
              final bookingId = docs[i].id;
              final vehicleId = booking['vehicleId'] as String;
              final userId = booking['userId'] as String;

              // Fetch user details for this booking:
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(userId).get(),
                builder: (ctx, userSnap) {
                  String userName = 'Loading…',
                      userPhone = '…',
                      userAddress = '…';
                  if (userSnap.connectionState == ConnectionState.done &&
                      userSnap.hasData &&
                      userSnap.data!.exists) {
                    final u = userSnap.data!.data() as Map<String, dynamic>;
                    userName = u['fullName'] ?? 'No Name';
                    userPhone = u['phoneNumber'] ?? 'No Phone';
                    userAddress = u['address'] ?? 'No Address';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// ————— Vehicle & User Info —————
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Vehicle image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  booking['imageUrl'] ?? '',
                                  width: 100,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        width: 100,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.directions_car,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Textual details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking['vehicleName'] ??
                                          'Unnamed Vehicle',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rate: ETB ${booking['rate']}/day',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Booked by: $userName'),
                                    Text('Phone: $userPhone'),
                                    Text('Address: $userAddress'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          /// ————— Schedule Info —————
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Pickup: ${formatTimestamp(booking['pickupDate'] as Timestamp)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Return: ${formatTimestamp(booking['returnDate'] as Timestamp)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// ————— Action Buttons —————
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed:
                                    () => rejectBooking(bookingId, vehicleId , userId),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed:
                                    () => approveBooking(bookingId, booking),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Approve'),
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
          );
        },
      ),
    );
  }
}
