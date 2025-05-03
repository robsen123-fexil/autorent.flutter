import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    simulateLoading();
  }

  void simulateLoading() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_progress >= 1) {
        timer.cancel();
        // Navigate to home or login screen after loading
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        setState(() {
          _progress += 0.01;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A73), // dark blue
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black, // Placeholder logo
              // backgroundImage: AssetImage('assets/logo.png'), // Use this if you have a real logo
            ),
            const SizedBox(height: 24),
            const Text(
              'Mohammed Vehicle Rentals',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Trusted Partner in Transportation',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white30,
                color: Colors.white,
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Loading... ${(_progress * 100).toInt()}%",
              style: const TextStyle(color: Colors.white70),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Text(
                    "Serving Ethiopia Since 2010",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "© 2024 Mohammed Vehicle Rentals. All rights reserved.",
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                    textAlign: TextAlign.center,
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
