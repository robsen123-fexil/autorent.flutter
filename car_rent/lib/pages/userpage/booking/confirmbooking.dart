import 'package:car_rent/pages/userpage/booking/payment/payment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class BookingScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;
  final String vehicleType;
  final String rate;
  final String imageUrl;

  const BookingScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleType,
    required this.rate,
    required this.imageUrl,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (DateTime date) {
        return date.weekday >= DateTime.monday &&
            date.weekday <= DateTime.saturday;
      },
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupTime = picked;
        } else {
          _returnTime = picked;
        }
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_pickupDate == null ||
        _pickupTime == null ||
        _returnDate == null ||
        _returnTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    if (_returnDate!.isBefore(_pickupDate!) ||
        (_returnDate == _pickupDate && _returnTime!.hour < _pickupTime!.hour)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return must be after pickup')),
      );
      return;
    }

    // Combine date and time
    final pickupDateTime = DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
      _pickupTime!.hour,
      _pickupTime!.minute,
    );

    final returnDateTime = DateTime(
      _returnDate!.year,
      _returnDate!.month,
      _returnDate!.day,
      _returnTime!.hour,
      _returnTime!.minute,
    );

    // Navigate to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TelebinPaymentScreen(
              totalAmount: _calculateTotalCost(),
              pickupDate: pickupDateTime,
              returnDate: returnDateTime,
              vehicleId: widget.vehicleId,
              vehicleName: widget.vehicleName,
              vehicleType: widget.vehicleType,
              imageUrl: widget.imageUrl,
              rate: widget.rate,
            ),
      ),
    );
  }

  double _calculateTotalCost() {
    final days = _returnDate!.difference(_pickupDate!).inDays + 1;
    return days * double.parse(widget.rate);
  }

  Widget _buildDatePickerButton(String label, DateTime? date, bool isPickup) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      onPressed: () => _selectDate(context, isPickup),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date == null
                ? 'Select $label Date'
                : DateFormat('EEE, MMM d').format(date),
          ),
          const Icon(Icons.calendar_today, size: 18),
        ],
      ),
    );
  }

  Widget _buildTimePickerButton(String label, TimeOfDay? time, bool isPickup) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      onPressed: () => _selectTime(context, isPickup),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time == null ? 'Select $label Time' : time.format(context)),
          const Icon(Icons.access_time, size: 18),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Vehicle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(widget.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.vehicleName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.vehicleType,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'ETB ${widget.rate}/day',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Pickup Details
            const Text(
              'Pickup Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDatePickerButton('Pickup', _pickupDate, true),
            const SizedBox(height: 8),
            _buildTimePickerButton('Pickup', _pickupTime, true),
            const SizedBox(height: 8),

            // Return Details
            const Text(
              'Return Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDatePickerButton('Return', _returnDate, false),
            const SizedBox(height: 8),
            _buildTimePickerButton('Return', _returnTime, false),
            const SizedBox(height: 8),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _confirmBooking,
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'CONFIRM BOOKING',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
