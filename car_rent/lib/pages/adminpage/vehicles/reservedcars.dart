import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ApprovedBookingsScreen extends StatefulWidget {
  const ApprovedBookingsScreen({super.key});

  @override
  _ApprovedBookingsScreenState createState() => _ApprovedBookingsScreenState();
}

class _ApprovedBookingsScreenState extends State<ApprovedBookingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to fetch approved bookings
  Stream<QuerySnapshot> getApprovedBookings() {
    return _firestore.collection('approved').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approved Bookings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getApprovedBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No approved bookings found.'));
          }

          final approvedVehicles = snapshot.data!.docs;

          return ListView.builder(
            itemCount: approvedVehicles.length,
            itemBuilder: (context, index) {
              final vehicle =
                  approvedVehicles[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        vehicle['imageUrl'],
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
                              vehicle['vehicleName'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Rate: ETB ${vehicle['rate']}'),
                            Text('Type: ${vehicle['vehicleType']}'),
                            const SizedBox(height: 8),
                            Text('User Email: ${vehicle['userEmail']}'),
                            const SizedBox(height: 8),
                            Text('Pickup Date: ${vehicle['pickupDate']}'),
                            Text('Pickup Time: ${vehicle['pickupTime']}'),
                            Text(
                              'Pickup Location: ${vehicle['pickupLocation']}',
                            ),
                            const SizedBox(height: 8),
                            Text('Return Date: ${vehicle['returnDate']}'),
                            Text('Return Time: ${vehicle['returnTime']}'),
                            Text(
                              'Return Location: ${vehicle['returnLocation']}',
                            ),
                          ],
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
