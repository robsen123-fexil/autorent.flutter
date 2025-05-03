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
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final rateController = TextEditingController();
  final featuresController = TextEditingController();

  String selectedType = '';
  String vehicleStatus = 'Available';
  final List<String> types = [
    'Sedan',
    'SUV',
    'Van',
    'Truck',
    'Hatchback',
    'Convertible',
  ];

  List<File> _pickedImages = [];
  List<String> _imageUrls = [];
  bool _isLoading = false;

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        maxWidth: 1000,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _pickedImages = pickedFiles.map((file) => File(file.path)).toList();
        });
      }
    } catch (e) {
      _showErrorDialog('Image picker error', e.toString());
    }
  }

  Future<void> _uploadImages() async {
    _imageUrls = [];
    for (final image in _pickedImages) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final ref = FirebaseStorage.instance.ref().child(
        'vehicle_images/$fileName',
      );
      await ref.putFile(image);
      final downloadUrl = await ref.getDownloadURL();
      _imageUrls.add(downloadUrl);
    }
  }

  Future<void> uploadVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _uploadImages();

      final featuresList =
          featuresController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      await FirebaseFirestore.instance.collection('vehicles').add({
        'name': nameController.text.trim(),
        'type': selectedType,
        'rate': double.parse(rateController.text.trim()),
        'image_url': _imageUrls.first,
        'image_urls': _imageUrls,
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
    _formKey.currentState?.reset();
    nameController.clear();
    rateController.clear();
    featuresController.clear();
    setState(() {
      selectedType = '';
      vehicleStatus = 'Available';
      _pickedImages = [];
      _imageUrls = [];
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'Vehicle Name*',
                        controller: nameController,
                        hint: 'Enter vehicle name',
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Required field'
                                    : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTypeDropdown(),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'Daily Rate (ETB)*',
                        controller: rateController,
                        hint: 'Enter daily rate',
                        isNumber: true,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required field';
                          if (double.tryParse(value!) == null) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildImagePicker(),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'Vehicle Features* (comma separated)',
                        controller: featuresController,
                        hint: 'Air Conditioning, Bluetooth, GPS',
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Required field'
                                    : null,
                      ),
                      const SizedBox(height: 20),
                      _buildStatusRadio(),
                      const SizedBox(height: 30),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Vehicle Details',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool isNumber = false,
    String? Function(String?)? validator,
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
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Type*',
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
            hintText: 'Select vehicle type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value == null ? 'Please select a type' : null,
        ),
      ],
    );
  }
 Future<void> _addImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1000,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      _showErrorDialog('Image picker error', e.toString());
    }
  }

 Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Images*',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              _pickedImages.isNotEmpty
                  ? GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: _pickedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _pickedImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap:
                                  () => setState(
                                    () => _pickedImages.removeAt(index),
                                  ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                  : const Center(
                    child: Text(
                      'No images selected.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
        ),
        const SizedBox(height: 10),

        // 🔥 This is your new "Add Image" button
        ElevatedButton.icon(
          onPressed: _addImage,
          icon: const Icon(Icons.add),
          label: const Text('Add Image'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }


  Widget _buildStatusRadio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status*', style: TextStyle(fontWeight: FontWeight.w500)),
        Row(
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
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: uploadVehicle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Add Vehicle',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Reset',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
