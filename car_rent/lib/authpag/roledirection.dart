// import 'package:flutter/material.dart';

// class RoleRedirectScreen extends StatefulWidget {
//   const RoleRedirectScreen({super.key});

//   @override
//   State<RoleRedirectScreen> createState() => _RoleRedirectScreenState();
// }

// class _RoleRedirectScreenState extends State<RoleRedirectScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   void initState() {
//     super.initState();
//     _checkUserAndRedirect();
//   }

//   Future<void> _checkUserAndRedirect() async {
//     final user = _auth.currentUser;

//     if (user == null) {
//       // Not logged in → go to login screen
//       Navigator.pushReplacementNamed(context, '/login');
//       return;
//     }

//     try {
//       // Check 'users' for customers
//       DocumentSnapshot userDoc =
//           await _firestore.collection('users').doc(user.uid).get();

//       if (!userDoc.exists) {
//         // If not found, check employees
//         userDoc = await _firestore.collection('employees').doc(user.uid).get();
//       }

//       if (userDoc.exists) {
//         final String role = userDoc.get('role');

//         if (role.toLowerCase() == 'customer') {
//           Navigator.pushReplacementNamed(context, '/car-rent');
//         } else {
//           Navigator.pushReplacementNamed(context, '/admin');
//         }
//       } else {
//         // No user data found, log out
//         await _auth.signOut();
//         Navigator.pushReplacementNamed(context, '/login');
//       }
//     } catch (e) {
//       print("Error checking role: $e");
//       await _auth.signOut();
//       Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(body: Center(child: SplashScreen()));
//   }
// }
