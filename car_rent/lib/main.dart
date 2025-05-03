import 'package:car_rent/authpag/authscreen.dart';
import 'package:car_rent/pages/adminpage/bookingm/bookingmanagement.dart';
import 'package:car_rent/pages/adminpage/vehicles/addvehicle.dart';
import 'package:car_rent/pages/adminpage/vehicles/listvehicles.dart';
import 'package:car_rent/pages/adminpage/vehicles/managevehicle.dart';
import 'package:car_rent/pages/userpage/booking/detailcaruser.dart';
import 'package:car_rent/pages/userpage/homescreen.dart';
import 'package:car_rent/pages/userpage/profile/profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            ); // Show a loading indicator while checking
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return snapshot.data!;
          }
        },
      ),
    );
  }

  // Determine which screen to show on app launch
  Future<Widget> _getInitialScreen() async {
    // Check if the user is logged in
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If the user is not logged in, navigate to Authscreen
      return Authscreen();
    }

    // If the user is logged in, check their role
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (userDoc.exists) {
      String role = userDoc['role'];

      // Navigate to the correct screen based on the role
      if (role == 'customer') {
        return CarRentHomeScreen(); // Navigate to HomeScreen if the user is a customer
      } else if (role == 'employee' || role=='manager' || role=='admin') {
        return CarRentHomeScreen(); // Navigate to ManageVehicleScreen if the user is an employee
      } else {
        return CarRentHomeScreen(); // If the role is undefined, go back to the Authscreen
      }
    } else {
      return CarRentHomeScreen(); // If no user data is found, navigate to Authscreen
    }
  }
}
