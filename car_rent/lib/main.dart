import 'package:car_rent/authpag/authscreen.dart';
import 'package:car_rent/firebase_options.dart';
import 'package:car_rent/pages/adminpage/bookingm/bookingmanagement.dart';
import 'package:car_rent/pages/adminpage/vehicles/addvehicle.dart';
import 'package:car_rent/pages/adminpage/vehicles/managevehicle.dart';
import 'package:car_rent/pages/userpage/booking/confirmbooking.dart';
import 'package:car_rent/pages/userpage/booking/detailcar.dart';
import 'package:car_rent/pages/userpage/homescreen.dart';
import 'package:car_rent/pages/userpage/profile/profile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AddNewVehicleScreen());
  }
}
