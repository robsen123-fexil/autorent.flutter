import 'package:car_rent/pages/adminpage/bookingm/bookingmanagement.dart';
import 'package:car_rent/pages/userpage/homescreen.dart';
import 'package:car_rent/authpag/authscreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // 👈 import spinkit

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkConnectionAndNavigate();
  }

  Future<void> _checkConnectionAndNavigate() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      _showNoInternetDialog();
      return;
    }

    await Future.delayed(const Duration(seconds: 2));
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _goTo(const Authscreen());
      return;
    } else {
      final uid = user.uid;
      final firestore = FirebaseFirestore.instance;
      try {
        final userDoc = await firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          _goTo(const CarRentHomeScreen());
          return;
        }

        final employeeDoc =
            await firestore.collection('employees').doc(uid).get();
        print(uid);
        if (employeeDoc.exists) {
          _goTo(const AdminDashboardScreen());
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Authscreen()),
        );
      } catch (e) {
        _showErrorDialog(
          
        "Due To Connection Issue.Please Try Again by Clicking TRY_AGAIN and Check ur Internet Connection Or Reopen Application Again. Thank you", 
        );
      }
    }
  }

  void _goTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFFE3F2FD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.redAccent),
                SizedBox(width: 10),
                Text(
                  "No Internet Connection",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              "Oops! Looks like you're offline.\nPlease connect to Wi-Fi or mobile data and try again.",
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                label: const Text(
                  "RETRY",
                  style: TextStyle(color: Colors.blueAccent),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _checkConnectionAndNavigate();
                },
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFFFFEBEE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.deepOrange),
                SizedBox(width: 10),
                Text(
                  "Connection Error",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.deepOrange),
                label: const Text(
                  "TRY AGAIN",
                  style: TextStyle(color: Colors.deepOrange),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _checkConnectionAndNavigate();
                },
              ),
            ],
          ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A237E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 100, left: 10),
              child: Column(
                children: [
                  Text(
                    'Mohammed Vehicle Rentals',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 43,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your Trusted Partner In Transportation',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w100,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),

            // 👇 This is your centered loading animation
            SpinKitThreeBounce(color: Colors.white, size: 40.0),

            Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  Text(
                    'Your Trusted Partner In Transportation',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w100,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2025 Mohammmed Vehicle Rentals Transportation',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w100,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
