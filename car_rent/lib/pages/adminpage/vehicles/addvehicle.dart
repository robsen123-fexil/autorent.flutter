import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path/path.dart';

class AddNewVehicleScreen extends StatefulWidget {
  const AddNewVehicleScreen({super.key});

  @override
  State<AddNewVehicleScreen> createState() => _AddNewVehicleScreenState();
}

class _AddNewVehicleScreenState extends State<AddNewVehicleScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController featuresController = TextEditingController();
 

  String selectedType = '';
  String vehicleStatus = 'Available';
  List<String> types = ['Sedan', 'SUV', 'Van', 'Truck'];

  File? _pickedImage;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadVehicle() async {
    if (_pickedImage == null ||
        nameController.text.isEmpty ||
        rateController.text.isEmpty ||
        selectedType.isEmpty ||
        featuresController.text.isEmpty ) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select an image.'),
        ),
      );
      return;
    }

    try {
      // Upload image to Firebase Storage
      String fileName = basename(_pickedImage!.path);
      Reference ref = FirebaseStorage.instance.ref().child(
        'vehicle_images/$fileName',
      );
      UploadTask uploadTask = ref.putFile(_pickedImage!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      
      List<String> featuresList =
          featuresController.text.split(',').map((e) => e.trim()).toList();
  

      // Upload vehicle details to Firestore
      await FirebaseFirestore.instance.collection('vehicles').add({
        'name': nameController.text.trim(),
        'type': selectedType,
        'rate': rateController.text.trim(),
        'image_url': downloadUrl,
        'status': vehicleStatus,
        'features': featuresList, // Features as a list
      
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text('Vehicle added successfully!')),
      );

      // Reset form
      nameController.clear();
      rateController.clear();
      featuresController.clear();

      setState(() {
        selectedType = '';
        vehicleStatus = 'Available';
        _pickedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context as BuildContext,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Add New Vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vehicle Name',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Enter vehicle name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vehicle Type',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedType.isEmpty ? null : selectedType,
                items:
                    types
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => selectedType = value!),
                decoration: InputDecoration(
                  hintText: 'Select type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Daily Rate (ETB)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter daily rate',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vehicle Image',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      _pickedImage != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_pickedImage!, fit: BoxFit.cover),
                          )
                          : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to upload image',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'Supports JPG, PNG',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Vehicle Features (comma separated)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: featuresController,
                decoration: InputDecoration(
                  hintText:
                      'Enter features (e.g., Air Conditioning, Bluetooth)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
             
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'Available',
                    groupValue: vehicleStatus,
                    onChanged:
                        (value) => setState(() => vehicleStatus = value!),
                  ),
                  const Text('Available'),
                  Radio<String>(
                    value: 'Unavailable',
                    groupValue: vehicleStatus,
                    onChanged:
                        (value) => setState(() => vehicleStatus = value!),
                  ),
                  const Text('Unavailable'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: uploadVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Vehicle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        nameController.clear();
                        rateController.clear();
                        featuresController.clear();
                       
                        setState(() {
                          selectedType = '';
                          vehicleStatus = 'Available';
                          _pickedImage = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Clear Form'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
