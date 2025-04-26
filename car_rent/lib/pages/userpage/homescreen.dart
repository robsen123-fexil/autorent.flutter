
import 'package:car_rent/pages/userpage/booking/detailcaruser.dart' show VehicleDetailScreen;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CarRentHomeScreen extends StatelessWidget {
  const CarRentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildCarList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A2D8F),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.notifications, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Mohammed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search vehicles...',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.filter_list),
            label: Text('Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Icon(Icons.view_list_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCarList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('vehicles')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No vehicles found.'));
        }

        final cars = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cars.length,
          itemBuilder: (context, index) {
            final car = cars[index];
            final carData = car.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                // Navigate to VehicleDetailScreen when the car card is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => VehicleDetailScreen(
                          vehicleId: car.id,
                          name: carData['name'] ?? 'Unnamed',
                          type: carData['type'] ?? 'Type',
                          imageUrl: carData['image_url'] ?? '',
                          pricePerDay: carData['rate']?.toString() ?? '0',
                          status: carData['status'] ?? 'Unknown',
                          specs: {
                            'Engine':
                                'V8', // Example: Replace with actual data from Firestore
                            'Color': 'Red',
                            // Add more specs from Firestore as needed
                          },
                          features: [
                            'Air Conditioning', // Example: Replace with actual features from Firestore
                            'Bluetooth',
                            // Add more features from Firestore as needed
                          ], data: {},
                        ),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        image:
                            carData['image_url'] != null
                                ? DecorationImage(
                                  image: NetworkImage(carData['image_url']),
                                  fit: BoxFit.cover,
                                )
                                : null,
                        color: Colors.grey[300],
                      ),
                      child:
                          carData['image_url'] == null
                              ? const Center(child: Text('No Image'))
                              : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  carData['name'] ?? 'Unnamed',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(carData['type'] ?? 'Type'),
                                const SizedBox(height: 4),
                                Text(
                                  'ETB ${carData['rate']}/day',
                                  style: const TextStyle(
                                    color: Color(0xFF0A2D8F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.5',
                                  ), // Or get from Firestore if available
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                carData['status'] ?? 'Unknown',
                                style: TextStyle(
                                  color:
                                      carData['status'] == 'Available'
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            ],
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
    );
  }

}
