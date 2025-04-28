import 'package:car_rent/pages/userpage/booking/detailcaruser.dart'
    show VehicleDetailScreen;
import 'package:car_rent/pages/userpage/profile/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CarRentHomeScreen extends StatefulWidget {
  const CarRentHomeScreen({super.key});

  @override
  State<CarRentHomeScreen> createState() => _CarRentHomeScreenState();
}

class _CarRentHomeScreenState extends State<CarRentHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'All';
  String _selectedStatus = 'All';

  final List<String> _vehicleTypes = ['All', 'Sedan', 'SUV', 'Van', 'Truck'];
  final List<String> _statusOptions = ['All', 'Available', 'Unavailable'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderSection(),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search vehicles...',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  items:
                      _vehicleTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items:
                      _statusOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedType = 'All';
                    _selectedStatus = 'All';
                    _searchController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Reset Filters'),
              ),
            ],
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

        var cars =
            snapshot.data!.docs.where((doc) {
              final carData = doc.data() as Map<String, dynamic>;
              final name = carData['name']?.toString().toLowerCase() ?? '';
              final type = carData['type']?.toString() ?? '';
              final status = carData['status']?.toString() ?? '';

              // Apply search filter
              if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
                return false;
              }

              // Apply type filter
              if (_selectedType != 'All' && type != _selectedType) {
                return false;
              }

              // Apply status filter
              if (_selectedStatus != 'All' && status != _selectedStatus) {
                return false;
              }

              return true;
            }).toList();

        if (cars.isEmpty) {
          return const Center(child: Text('No vehicles match your filters.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cars.length,
          itemBuilder: (context, index) {
            final car = cars[index];
            final carData = car.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
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
                          features: List<String>.from(
                            carData['features'] ??
                                ['Air Conditioning', 'Bluetooth'],
                          ),
                          data: {},
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
                                children: const [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 4),
                                  Text('4.5'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                carData['status'] ?? 'Unknown',
                                style: TextStyle(
                                  color:
                                      (carData['status'] == 'Available')
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

class HeaderSection extends StatefulWidget {
  const HeaderSection({super.key});

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  String username = 'Loading...';
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final docSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          setState(() {
            username = data?['fullName'] ?? 'User';
            profileImageUrl = data?['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfileScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                      child:
                          profileImageUrl == null
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
