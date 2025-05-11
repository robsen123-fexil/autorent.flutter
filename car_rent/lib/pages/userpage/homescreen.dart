import 'dart:async';
import 'package:car_rent/pages/userpage/booking/detailcaruser.dart'
    show VehicleDetailScreen;
import 'package:car_rent/pages/userpage/profile/mybooking.dart';
import 'package:car_rent/pages/userpage/profile/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CarRentHomeScreen extends StatefulWidget {
  const CarRentHomeScreen({super.key});

  @override
  State<CarRentHomeScreen> createState() => _CarRentHomeScreenState();
}

class _CarRentHomeScreenState extends State<CarRentHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RefreshController _refreshController = RefreshController();
  String _searchQuery = '';
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  bool _showNotifications = false;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  final List<String> _vehicleTypes = ['All', 'Sedan', 'SUV', 'Van', 'Truck'];
  final List<String> _statusOptions = ['All', 'Available', 'Unavailable'];

  @override
  void initState() {
    super.initState();
    _initializeListeners();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    _notificationsSubscription?.cancel();
    _bookingsSubscription?.cancel();
    super.dispose();
  }

  void _initializeListeners() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Notifications listener
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _handleNotificationsUpdate(snapshot);
        });

    // Bookings listener
    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _handleNewBookings(snapshot);
        });
  }

  Future<void> _loadInitialData() async {
    await _refreshNotifications();
    _refreshController.refreshCompleted();
  }

  Future<void> _refreshNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();

    _handleNotificationsUpdate(snapshot);
  }

  void _handleNotificationsUpdate(QuerySnapshot snapshot) {
    if (!mounted) return;

    setState(() {
      _notifications =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Notification',
              'message': data['message'] ?? '',
              'time': DateFormat(
                'MMM dd, hh:mm a',
              ).format(data['createdAt'].toDate()),
              'isRead': data['isRead'] ?? false,
              'type': data['type'],
              'bookingId': data['bookingId'],
              'vehicleId': data['vehicleId'],
            };
          }).toList();

      _unreadCount = _notifications.where((n) => !n['isRead']).length;
    });
  }

  void _handleNewBookings(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) return;

    final newBookings = snapshot.docChanges.where(
      (change) => change.type == DocumentChangeType.added,
    );

    for (final change in newBookings) {
      final booking = change.doc.data() as Map<String, dynamic>;
      _addBookingNotification(booking, change.doc.id);
    }
  }

  Future<void> _addBookingNotification(
    Map<String, dynamic> booking,
    String bookingId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if notification already exists
    final existingNotification =
        await FirebaseFirestore.instance
            .collection('notifications')
            .where('bookingId', isEqualTo: bookingId)
            .limit(1)
            .get();

    if (existingNotification.docs.isNotEmpty) return;

    final notification = {
      'title': 'Booking Confirmed',
      'message':
          'Your booking for ${booking['vehicleName']} is confirmed. '
          'Pickup on ${DateFormat('MMM dd, yyyy').format(booking['pickupDate'].toDate())} '
          'at ${booking['pickupTime']}',
      'isRead': false,
      'userId': user.uid,
      'type': 'booking_confirmation',
      'createdAt': Timestamp.now(),
      'bookingId': bookingId,
      'vehicleId': booking['vehicleId'],
    };

    await FirebaseFirestore.instance
        .collection('notifications')
        .add(notification);
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> _markAllNotificationsAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final snapshot =
        await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .where('isRead', isEqualTo: false)
            .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
      if (_showNotifications && _unreadCount > 0) {
        _markAllNotificationsAsRead();
      }
    });
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    // Mark as read if not already
    if (!notification['isRead']) {
      await _markNotificationAsRead(notification['id']);
    }

    // Handle different notification types
    switch (notification['type']) {
      case 'booking_confirmation':
        // Navigate to booking details
        break;
      default:
        // Default behavior
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            SmartRefresher(
              controller: _refreshController,
              onRefresh: _refreshNotifications,
              header: const ClassicHeader(
                idleText: 'Pull to refresh',
                releaseText: 'Release to refresh',
                completeText: 'Refresh complete',
                refreshingText: 'Refreshing...',
                failedText: 'Refresh failed',
              ),
              child: Column(
                children: [
                  HeaderSection(
                    onNotificationPressed: _toggleNotifications,
                    unreadCount: _unreadCount,
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildCarList()),
                ],
              ),
            ),

            // Notification Panel
            if (_showNotifications)
              Positioned(
                top: 100,
                right: 16,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: _refreshNotifications,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _toggleNotifications,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Expanded(
                          child:
                              _notifications.isEmpty
                                  ? const Center(
                                    child: Text('No notifications'),
                                  )
                                  : ListView.builder(
                                    itemCount: _notifications.length,
                                    itemBuilder: (context, index) {
                                      final notification =
                                          _notifications[index];
                                      return _buildNotificationItem(
                                        notification,
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        color: notification['isRead'] ? Colors.white : Colors.blue[50],
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    notification['title'],
                    style: TextStyle(
                      fontWeight:
                          notification['isRead']
                              ? FontWeight.normal
                              : FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  notification['time'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              notification['message'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            const Divider(),
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

              if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
                return false;
              }

              if (_selectedType != 'All' && type != _selectedType) {
                return false;
              }

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
                          imageUrls: List<String>.from(
                            carData['image_urls'] ??
                                [carData['image_url'] ?? ''],
                          ),
                          data: carData,
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
  final VoidCallback onNotificationPressed;
  final int unreadCount;

  const HeaderSection({
    super.key,
    required this.onNotificationPressed,
    required this.unreadCount,
  });

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
      debugPrint('Error loading user data: $e');
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
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                        onPressed:
                            widget
                                .onNotificationPressed, // ✅ valid only in State
                      ),
                      if (widget.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              widget.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyBookingsScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.taxi_alert, color: Colors.white),
                  ),
                  SizedBox(width: 8),

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
