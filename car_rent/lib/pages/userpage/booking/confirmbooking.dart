import 'package:car_rent/pages/userpage/booking/payment/payment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    DateTime today = DateTime.now();

    // Ensure initialDate is not Sunday
    DateTime initialDate = today;
    if (today.weekday == DateTime.sunday) {
      initialDate = today.add(const Duration(days: 1)); // push to Monday
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        return date.weekday >= DateTime.monday &&
            date.weekday <= DateTime.saturday;
      },
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
          _pickupTime ??= TimeOfDay.now();
        } else {
          _returnDate = picked;
          _returnTime ??= TimeOfDay.now();
        }
      });
    }
  }


  Future<void> _selectTime(BuildContext context, bool isPickup) async {
    final initialTime =
        isPickup
            ? (_pickupTime ?? TimeOfDay.now())
            : (_returnTime ?? TimeOfDay.now());

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
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

    if (returnDateTime.isBefore(pickupDateTime)) {
      // Fixed typo here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return must be after pickup')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _calculateTotalCost() {
    if (_pickupDate == null || _returnDate == null) return 0.0;
    final days = _returnDate!.difference(_pickupDate!).inDays + 1;
    return days * double.parse(widget.rate);
  }

  Widget _buildDatePickerButton(String label, DateTime? date, bool isPickup) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Added this to prevent gesture issues
      onTap: () => _selectDate(context, isPickup),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null
                  ? 'Select $label Date'
                  : DateFormat('EEE, MMM d, yyyy').format(date),
              style: TextStyle(
                fontSize: 16,
                color: date == null ? Colors.grey : Colors.black87,
              ),
            ),
            const Icon(Icons.calendar_today, size: 18, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerButton(String label, TimeOfDay? time, bool isPickup) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Added this to prevent gesture issues
      onTap: () => _selectTime(context, isPickup),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              time == null ? 'Select $label Time' : time.format(context),
              style: TextStyle(
                fontSize: 16,
                color: time == null ? Colors.grey : Colors.black87,
              ),
            ),
            const Icon(Icons.access_time, size: 18, color: Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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

            const Text(
              'Pickup Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDatePickerButton('Pickup', _pickupDate, true),
            const SizedBox(height: 8),
            _buildTimePickerButton('Pickup', _pickupTime, true),
            const SizedBox(height: 16),

            const Text(
              'Return Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDatePickerButton('Return', _returnDate, false),
            const SizedBox(height: 8),
            _buildTimePickerButton('Return', _returnTime, false),
            const SizedBox(height: 24),

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
