import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReturnApprovalScreen extends StatelessWidget {
  const AdminReturnApprovalScreen({super.key});

  Future<void> _handleApproval(
    BuildContext context,
    DocumentSnapshot returnDoc,
    bool isApproved,
  ) async {
    final vehicleId = returnDoc['vehicleId'];
    final returnDocId = returnDoc.id;

    try {
      if (isApproved) {
        final vehicleDoc =
            await FirebaseFirestore.instance
                .collection('vehicles')
                .doc(vehicleId)
                .get();

        if (vehicleDoc.exists && vehicleDoc['status'] != 'available') {
          await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(vehicleId)
              .update({'status': 'Available'});
        }

        await FirebaseFirestore.instance
            .collection('returned')
            .doc(returnDocId)
            .update({'status': 'verified', 'adminCheckedAt': Timestamp.now()});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Marked as returned and vehicle is now available."),
          ),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('returned')
            .doc(returnDocId)
            .update({'status': 'rejected', 'adminCheckedAt': Timestamp.now()});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Marked as not returned.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final returnsStream =
        FirebaseFirestore.instance
            .collection('returned')
            .where('status', isNotEqualTo: 'verified') // Filter only pending
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back ,color: Colors.white,),
        ),
        title: const Text(
          'Verify Returned Vehicles',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 28, 5, 104),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: returnsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No return requests pending."));
          }

          final returnedList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: returnedList.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final doc = returnedList[index];
              final vehicleName = doc['vehicleName'];
              final userId = doc['userId'];
              final pickupDate = (doc['pickupDate'] as Timestamp).toDate();
              final returnDate = (doc['returnDate'] as Timestamp).toDate();
              final status = doc['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 6),
                      Text("User ID: $userId"),
                      Text("Pickup: ${pickupDate.toLocal()}"),
                      Text("Return: ${returnDate.toLocal()}"),

                      Text(
                        "Status: ${status.toUpperCase()}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              status == 'rejected'
                                  ? Colors.red
                                  : status == 'verified'
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                () => _handleApproval(context, doc, true),
                            icon: const Icon(Icons.check),
                            label: const Text("Yes, Returned"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed:
                                () => _handleApproval(context, doc, false),
                            icon: const Icon(Icons.close),
                            label: const Text("No, Not Yet"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
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
