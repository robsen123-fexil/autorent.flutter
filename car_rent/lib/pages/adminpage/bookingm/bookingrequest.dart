import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Bookingrequest extends StatefulWidget {
  const Bookingrequest({super.key});

  @override
  _BookingrequestState createState() => _BookingrequestState();
}

class _BookingrequestState extends State<Bookingrequest> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the reserved vehicles from Firestore
  Stream<QuerySnapshot> getReservedVehicles() {
    return _firestore.collection('reserved').snapshots();
  }

  // Function to approve booking
  void approveBooking(
    String vehicleId,
    Map<String, dynamic> vehicleData,
  ) async {
    try {
      // Add the vehicle to the 'approved' collection
      await _firestore.collection('approved').add(vehicleData);

      // Remove the vehicle from the 'reserved' collection
      await _firestore.collection('reserved').doc(vehicleId).delete();

      // Optionally: Update the vehicle's status in its own collection (if necessary)
      await _firestore
          .collection('vehicles')
          .doc(vehicleData['vehicleId'])
          .update({'status': 'Approved'});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking Approved!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to approve: $e')));
    }
  }

  // Function to reject booking
  void rejectBooking(String vehicleId) async {
    try {
      // Remove the booking from 'reserved'
      await _firestore.collection('reserved').doc(vehicleId).delete();

      // Optionally: Update the vehicle's status to 'available'
      await _firestore.collection('vehicles').doc(vehicleId).update({
        'status': 'Available',
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking Rejected!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Vehicle Bookings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getReservedVehicles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No reserved vehicles.'));
          }

          final reservedVehicles = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reservedVehicles.length,
            itemBuilder: (context, index) {
              final vehicle =
                  reservedVehicles[index].data() as Map<String, dynamic>;
              final vehicleId = reservedVehicles[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.network(
                            vehicle['imageUrl'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle['vehicleName'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ETB ${vehicle['rate']} /day',
                                style: const TextStyle(color: Colors.blue),
                              ),
                              Text(
                                'User Email: ${vehicle['userEmail']}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pickup: ${vehicle['pickupDate']} at ${vehicle['pickupTime']}',
                              ),
                              Text(
                                'Return: ${vehicle['returnDate']} at ${vehicle['returnTime']}',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => approveBooking(vehicleId, vehicle),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => rejectBooking(vehicleId),
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
