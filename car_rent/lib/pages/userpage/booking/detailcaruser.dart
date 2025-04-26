import 'package:car_rent/pages/userpage/booking/confirmbooking.dart';
import 'package:flutter/material.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;
  final String name;
  final String type;
  final String imageUrl;
  final String pricePerDay;
  final String status;

  final Map<String, String> specs;
  final List<String> features;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.pricePerDay,
    required this.status,
    required this.specs,
    required this.features, required Map<String, dynamic> data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(name, style: const TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle image
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Specs
            ...specs.entries.map((e) => _buildSpec(e.key, e.value)),

            const SizedBox(height: 16),
            const Text(
              "Features & Amenities",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...features.map(_buildFeature),

            const SizedBox(height: 24),
            // Price and availability
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Price per day",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      "ETB $pricePerDay",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        status == "Available"
                            ? Colors.green[100]
                            : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == "Available" ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Reserve button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    status != "Available"
                        ? null
                        : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => BookingScreen(
                                    vehicleId: vehicleId,
                                    vehicleName: name,
                                    vehicleType: type,
                                    rate: pricePerDay,
                                    imageUrl: imageUrl,
                                  ),
                            ),
                          );
                        },
                child: const Text(
                  "Reserve Now",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpec(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }
}
