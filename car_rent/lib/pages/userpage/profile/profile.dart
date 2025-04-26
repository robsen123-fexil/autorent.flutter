import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Mohammed Ahmed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'mohammed.ahmed@example.com',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Divider(),
            ProfileDetail(title: 'Full Name', value: 'Mohammed Ahmed'),
            ProfileDetail(title: 'Phone Number', value: '+251 91 234 5678'),
            ProfileDetail(
              title: 'Email Address',
              value: 'mohammed.ahmed@example.com',
            ),
            ProfileDetail(title: 'Address', value: 'Bole, Addis Ababa'),
            
            SizedBox(height: 150),

            ElevatedButton(
              onPressed: () {
                
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue[900],
                minimumSize: Size(double.infinity, 36),
              ),
              child: Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDetail extends StatelessWidget {
  final String title;
  final String value;

  const ProfileDetail({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
