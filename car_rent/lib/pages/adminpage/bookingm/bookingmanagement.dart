import 'package:car_rent/pages/adminpage/addemployee.dart';
import 'package:car_rent/pages/adminpage/listusers.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const DrawerMenu(),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 100,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 30),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                const SizedBox(width: 16),
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Real-time Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back, Admin",
                    style: TextStyle(color: Colors.black, fontSize: 30),
                  ),
                  const SizedBox(height: 24),

                  buildDashboardStreamCard(
                    title: "Total Vehicles",
                    collection: "vehicles",
                    icon: Icons.directions_car_filled,
                    color: Colors.blue[100]!,
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
                    icon: Icons.calendar_today,
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
                    title: "Reserved",
                    collection: "reserved",
                    icon: Icons.approval,
                    color: Colors.orange[100]!,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Bookingrequest(),
                          ),
                        ),
                  ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        int count = snapshot.data?.docs.length ?? 0;

        return GestureDetector(
          onTap: onTap,
          child: DashboardCard(
            title: title,
            value: count.toString(),
            icon: icon,
            iconBgColor: color,
          ),
        );
      },
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBgColor;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 233, 232, 232),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.black87, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Text("Admin Panel", style: TextStyle(fontSize: 20)),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
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
                  Icons.calendar_today,
                  "Bookings",
                  () => const Bookingrequest(),
                  context,
                ),
                buildDrawerItem(
                  Icons.people,
                  "Users and Customers List",
                  () => const CustomerAndEmployeeListScreen(),
                  context,
                ),
                buildDrawerItem(
                  Icons.person,
                  "Add Employee",
                  () => const AddEmployeeScreen(),
                  context,
                ),
              ],
            ),
          ),
          const Divider(),
          buildDrawerItem(
            Icons.logout,
            "Logout",
            () => const Authscreen(),
            context,
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
