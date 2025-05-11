import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ApprovedBookingsScreen extends StatefulWidget {
  const ApprovedBookingsScreen({super.key});

  @override
  _ApprovedBookingsScreenState createState() => _ApprovedBookingsScreenState();
}

class _ApprovedBookingsScreenState extends State<ApprovedBookingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getApprovedBookings() {
    return _firestore.collection('reserved').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: const Text('Approved Bookings'),
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 8, 60, 113),
        centerTitle: true,
      ),
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

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>?;

              if (booking == null) return const SizedBox();

              final imageUrl = booking['imageUrl'] ?? '';
              final vehicleName = booking['vehicleName'] ?? 'Unknown Vehicle';
              final rate = booking['rate'] ?? 'N/A';
              final type = booking['vehicleType'] ?? 'N/A';
              final email = booking['userEmail'] ?? 'N/A';
              final pickupDate = booking['pickupDate'] ?? 'N/A';
              final pickupTime = booking['pickupTime'] ?? 'N/A';
              final pickupLocation = booking['pickupLocation'] ?? 'N/A';
              final returnDate = booking['returnDate'] ?? 'N/A';
              final returnTime = booking['returnTime'] ?? 'N/A';
              final returnLocation = booking['returnLocation'] ?? 'N/A';
              final pickupTimestamp = booking['pickupDate'] as Timestamp?;
              final returnTimestamp = booking['returnDate'] as Timestamp?;

              final pickupDateTime = pickupTimestamp?.toDate();
              final returnDateTime = returnTimestamp?.toDate();

              final formattedPickupDate =
                  pickupDateTime != null
                      ? DateFormat('EEEE, MMM d, y').format(pickupDateTime)
                      : 'Unknown';
              final formattedPickupTime =
                  pickupDateTime != null
                      ? DateFormat('h:mm a').format(pickupDateTime)
                      : 'Unknown';

              final formattedReturnDate =
                  returnDateTime != null
                      ? DateFormat('EEEE, MMM d, y').format(returnDateTime)
                      : 'Unknown';
              final formattedReturnTime =
                  returnDateTime != null
                      ? DateFormat('h:mm a').format(returnDateTime)
                      : 'Unknown';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                imageUrl.isNotEmpty
                                    ? Image.network(
                                      imageUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                    : Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.directions_car),
                                    ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicleName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('ETB $rate • $type'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      const Text(
                        'User Details',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Email: $email'),

                      const SizedBox(height: 8),
                      const Text(
                        'Pickup Info',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Date: $formattedPickupDate'),
                      Text('Time: $formattedPickupTime'),
                      Text('Location: $pickupLocation'),

                      const SizedBox(height: 8),
                      const Text(
                        'Return Info',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Date: $formattedReturnDate'),
                      Text('Time: $formattedPickupTime'),
                      Text('Location: $returnLocation'),
                      SizedBox(height: 8),
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
