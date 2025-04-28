import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;
  final String vehicleType;
  final String rate;
  final String imageUrl;

  const BookingScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleType,
    required this.rate,
    required this.imageUrl,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController pickupDateController = TextEditingController();
  final TextEditingController pickupTimeController = TextEditingController();
  final TextEditingController pickupLocationController =
      TextEditingController();

  final TextEditingController returnDateController = TextEditingController();
  final TextEditingController returnTimeController = TextEditingController();
  final TextEditingController returnLocationController =
      TextEditingController();

  bool isLoading = false;

  // Function to get current user from FirebaseAuth
  User? getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    return user;
  }

  void _confirmBooking() async {
    if (pickupDateController.text.isEmpty ||
        pickupTimeController.text.isEmpty ||
        pickupLocationController.text.isEmpty ||
        returnDateController.text.isEmpty ||
        returnTimeController.text.isEmpty ||
        returnLocationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      User? currentUser = getCurrentUser();
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user logged in')));
        return;
      }

      // Add the reservation to Firestore
      await FirebaseFirestore.instance.collection('reserved').add({
        'vehicleId': widget.vehicleId,
        'vehicleName': widget.vehicleName,
        'vehicleType': widget.vehicleType,
        'rate': widget.rate,
        'imageUrl': widget.imageUrl,
        'pickupDate': pickupDateController.text,
        'pickupTime': pickupTimeController.text,
        'pickupLocation': pickupLocationController.text,
        'returnDate': returnDateController.text,
        'returnTime': returnTimeController.text,
        'returnLocation': returnLocationController.text,
        'createdAt': Timestamp.now(),
        'status': 'Pending',
        'userId': currentUser.uid, // Store current user's UID
        'userEmail': currentUser.email, // Store current user's email (optional)
        'userDisplayName':
            currentUser.displayName ??
            'Unknown', // Store user's name (optional)
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking Confirmed!')));
      Navigator.pop(context); // go back to home or previous screen
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to book: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildInputField(String hinttext,TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
      
        controller: controller,
        decoration: InputDecoration(
          hintText: hinttext,
       
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Book Your Vehicle",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.imageUrl),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.vehicleName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.vehicleType,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'ETB ${widget.rate}/day',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                buildSectionTitle("Pickup Details"),
                buildInputField('example:Monday ' ,pickupDateController),
                buildInputField('example:Morning 9:00am',  pickupTimeController),
                buildInputField(  'example: current Office', pickupLocationController),
                const SizedBox(height: 24),
                buildSectionTitle("Return Details"),
                buildInputField( 'example:Friday',  returnDateController),
                buildInputField('example:Afternoon 4:00pm', returnTimeController),
                buildInputField('currentOfice', returnLocationController),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isLoading ? null : _confirmBooking,
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "Confirm Booking",
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
