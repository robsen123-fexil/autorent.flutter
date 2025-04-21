import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart';

class AddVehicles {
  Future<void> uploadVehicle({
    required String name,
    required String type,
    required String rate,
    required File imageFile,
    required String status,
    required String featuresInput, // Comma separated features
 
  }) async {
    try {
      // Upload image to Firebase Storage
      String fileName = basename(imageFile.path);
      Reference ref = FirebaseStorage.instance.ref().child(
        'vehicle_images/$fileName',
      );
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Convert comma-separated string inputs into lists
      List<String> featuresList =
          featuresInput.split(',').map((e) => e.trim()).toList();
    

      // Add data to Firestore
      await FirebaseFirestore.instance.collection('vehicles').add({
        'name': name,
        'type': type,
        'rate': rate,
        'image_url': downloadUrl,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(), // For sorting or tracking
        'features': featuresList, // Store as an array of strings
      
      });

      print("✅ Vehicle uploaded successfully!");
    } catch (e) {
      print("❌ Failed to upload vehicle: $e");
    }
  }
}
