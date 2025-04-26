import 'dart:io';
import 'package:car_rent/pages/adminpage/vehicles/managevehicle.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class AddNewVehicleScreen extends StatefulWidget {
  const AddNewVehicleScreen({super.key});

  @override
  State<AddNewVehicleScreen> createState() => _AddNewVehicleScreenState();
}

class _AddNewVehicleScreenState extends State<AddNewVehicleScreen> {
  final nameController = TextEditingController();
  final rateController = TextEditingController();
  final featuresController = TextEditingController();

  String selectedType = '';
  String vehicleStatus = 'Available';
  final List<String> types = ['Sedan', 'SUV', 'Van', 'Truck'];
  File? _pickedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _pickedImage = File(pickedFile.path));
      }
    } catch (e) {
      _showErrorDialog('Image picker error', e.toString());
    }
  }

  Future<void> uploadVehicle() async {
    if (_pickedImage == null ||
        nameController.text.trim().isEmpty ||
        rateController.text.trim().isEmpty ||
        selectedType.isEmpty ||
        featuresController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select an image.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_pickedImage!.path)}';
      final ref = FirebaseStorage.instance.ref().child(
        'vehicle_images/$fileName',
      );
      await ref.putFile(_pickedImage!);
      final downloadUrl = await ref.getDownloadURL();

      final featuresList =
          featuresController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      await FirebaseFirestore.instance.collection('vehicles').add({
        'name': nameController.text.trim(),
        'type': selectedType,
        'rate': rateController.text.trim(),
        'image_url': downloadUrl,
        'status': vehicleStatus,
        'features': featuresList,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      await _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Upload failed', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text(
              'Success!',
              style: TextStyle(color: Colors.green),
            ),
            content: const Text('Vehicle added successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetForm();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const VehicleManagementScreen(),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title, style: const TextStyle(color: Colors.red)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _resetForm() {
    nameController.clear();
    rateController.clear();
    featuresController.clear();
    setState(() {
      selectedType = '';
      vehicleStatus = 'Available';
      _pickedImage = null;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    rateController.dispose();
    featuresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Vehicle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 20),
                    _textField(
                      label: 'Vehicle Name',
                      controller: nameController,
                      hint: 'Enter vehicle name',
                    ),
                    const SizedBox(height: 20),
                    _dropdownField(),
                    const SizedBox(height: 20),
                    _textField(
                      label: 'Daily Rate (ETB)',
                      controller: rateController,
                      hint: 'Enter daily rate',
                      isNumber: true,
                    ),
                    const SizedBox(height: 20),
                    _imagePicker(),
                    const SizedBox(height: 20),
                    _textField(
                      label: 'Vehicle Features (comma separated)',
                      controller: featuresController,
                      hint: 'Air Conditioning, Bluetooth',
                    ),
                    const SizedBox(height: 20),
                    _statusRadio(),
                    const SizedBox(height: 20),
                    _actionButtons(),
                  ],
                ),
              ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => selectedType = value!),
          decoration: InputDecoration(
            hintText: 'Select type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _imagePicker() {
    return GestureDetector(
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
                      Icon(Icons.image_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Tap to upload image',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Supports JPG, PNG',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _statusRadio() {
    return Row(
      children: [
        Radio<String>(
          value: 'Available',
          groupValue: vehicleStatus,
          onChanged: (value) => setState(() => vehicleStatus = value!),
        ),
        const Text('Available'),
        Radio<String>(
          value: 'Unavailable',
          groupValue: vehicleStatus,
          onChanged: (value) => setState(() => vehicleStatus = value!),
        ),
        const Text('Unavailable'),
      ],
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: uploadVehicle,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
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
            onPressed: _resetForm,
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
    );
  }
}
