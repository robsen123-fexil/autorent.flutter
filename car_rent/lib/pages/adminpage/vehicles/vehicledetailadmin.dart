import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleManageDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> vehicleData;

  const VehicleManageDetailScreen({
    super.key,
    required this.docId,
    required this.vehicleData,
  });

  @override
  State<VehicleManageDetailScreen> createState() =>
      _VehicleManageDetailScreenState();
}

class _VehicleManageDetailScreenState extends State<VehicleManageDetailScreen> {
  late TextEditingController nameController;
  late TextEditingController typeController;
  late TextEditingController rateController;
  late TextEditingController imageUrlController;

  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.vehicleData['name']);
    typeController = TextEditingController(text: widget.vehicleData['type']);
    rateController = TextEditingController(
      text: widget.vehicleData['rate'].toString(),
    );
    imageUrlController = TextEditingController(
      text: widget.vehicleData['image_url'],
    );
  }

  Future<void> updateVehicle() async {
    setState(() => isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.docId)
          .update({
            'name': nameController.text,
            'type': typeController.text,
            'rate': double.tryParse(rateController.text) ?? 0,
            'image_url': imageUrlController.text,
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vehicle updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
    }

    setState(() => isUpdating = false);
  }

  Future<void> deleteVehicle() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Delete Vehicle"),
            content: const Text(
              "Are you sure you want to delete this vehicle?",
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(ctx, false),
              ),
              TextButton(
                child: const Text("Delete"),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.docId)
            .delete();
        Navigator.pop(context); // Go back after deleting
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vehicle deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Vehicle'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            
            if (imageUrlController.text.isNotEmpty)
              Image.network(imageUrlController.text, height: 150),
              SizedBox(height: 20,),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Vehicle Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'Vehicle Type'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rate (ETB)'),
            ),
        
            const SizedBox(height: 40),

            Row(
              children: [
                ElevatedButton(
                  onPressed: isUpdating ? null : updateVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white
                  ),
                  child:
                      isUpdating
                          ? const CircularProgressIndicator()
                          : const Text('Update Vehicle'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: deleteVehicle,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                  ),
                  child: const Text('Delete Vehicle'),
                ),
              ],
            )
            
          ],
        ),
      ),
    );
  }
}
