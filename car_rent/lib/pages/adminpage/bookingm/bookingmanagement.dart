import 'package:car_rent/pages/adminpage/addemployee.dart';
import 'package:car_rent/pages/adminpage/bookingm/feedback.dart';
import 'package:car_rent/pages/adminpage/bookingm/reservehistory.dart';
import 'package:car_rent/pages/adminpage/bookingm/returnedbook.dart';
import 'package:car_rent/pages/adminpage/listusers.dart';
import 'package:car_rent/pages/adminpage/vehicles/reservedcars.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_rent/authpag/authscreen.dart';
import 'package:car_rent/pages/adminpage/bookingm/bookingrequest.dart';
import 'package:car_rent/pages/adminpage/vehicles/managevehicle.dart';
import 'package:car_rent/pages/userpage/homescreen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Authscreen()),
                  );
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerMenu(onLogout: _showLogoutDialog),
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF283593),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Welcome back, Admin ",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: [
                  buildDashboardStreamCard(
                    title: "Total Vehicles",
                    collection: "vehicles",
                    icon: Icons.directions_car,
                    color: Colors.lightBlue[100]!,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VehicleManagementScreen(),
                          ),
                        ),
                  ),
                  const SizedBox(height: 16),
                  buildDashboardStreamCard(
                    title: "Active Bookings",
                    collection: "bookings",
                    icon: Icons.event_note,
                    color: Colors.green[100]!,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Bookingrequest(),
                          ),
                        ),
                  ),
                  const SizedBox(height: 16),
                  buildDashboardStreamCard(
                    title: "Approved Reservations",
                    collection: "reserved",
                    icon: Icons.verified,
                    color: Colors.orange[100]!,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ApprovedBookingsScreen(),
                          ),
                        ),
                  ),
                  const SizedBox(height: 16),
                  buildDashboardStreamCard(
                    title: "Returned Reservations",
                    collection: "returned",
                    icon: Icons.assignment_returned,
                    color: Colors.orange[100]!,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminReturnApprovalScreen(),
                          ),
                        ),
                  ),
                    const SizedBox(height: 16),
                  buildDashboardStreamCard(
                    title: "Returned History",
                    collection: "returned",
                    icon: Icons.assignment_returned,
                    color: Colors.orange[100]!,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReservationHistoryScreen(),
                          ),
                        ),
                  ),
                  const SizedBox(height: 16),
                  buildDashboardStreamCard(
                    title: "User Feedback",
                    collection: "returned",
                    icon: Icons.assignment_returned,
                    color: Colors.orange[100]!,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserFeedbackScreen(),
                          ),
                        ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDashboardStreamCard({
    required String title,
    required String collection,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Icon(icon, size: 28, color: Colors.black87),
                  radius: 28,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count records',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 30, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DrawerMenu extends StatelessWidget {
  final VoidCallback onLogout;

  const DrawerMenu({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF1A237E)),
            child: Center(
              child: Text(
                "Admin Panel",
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),
          ),
          buildDrawerItem(
            Icons.home,
            "Home",
            () => const CarRentHomeScreen(),
            context,
          ),
          buildDrawerItem(
            Icons.directions_car,
            "Vehicles",
            () => const VehicleManagementScreen(),
            context,
          ),
          buildDrawerItem(
            Icons.event,
            "Bookings",
            () => const Bookingrequest(),
            context,
          ),
          buildDrawerItem(
            Icons.people,
            "User List",
            () => const CustomerAndEmployeeListScreen(),
            context,
          ),
          buildDrawerItem(
            Icons.person_add,
            "Add Employee",
            () => const AddEmployeeScreen(),
            context,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget buildDrawerItem(
    IconData icon,
    String title,
    Widget Function() nav,
    BuildContext context,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => nav()));
      },
    );
  }
}
