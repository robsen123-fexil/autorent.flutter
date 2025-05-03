import 'package:car_rent/pages/userpage/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class PaymentService {
  // Process payment and confirm booking
  static Future<void> processPayment({
    required BuildContext context,
    required double totalAmount,
    required String vehicleId,
    required double rate,
    required String vehicleName,
    required String vehicleType,
    required String imageUrl,
    required DateTime pickupDate,
    required DateTime returnDate,
  }) async {
    final navigator = Navigator.of(context);
    final overlayContext = navigator.overlay!.context;

    // Show loading dialog
    showDialog(
      context: overlayContext,
      barrierDismissible: false,
      builder: (dialogContext) => const PaymentProcessingDialog(),
    );

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Confirm booking and process payment
      await _confirmBooking(
        context: context,
        rate: rate,
        vehicleId: vehicleId,
        vehicleName: vehicleName,
        vehicleType: vehicleType,
        imageUrl: imageUrl,
        pickupDate: pickupDate,
        returnDate: returnDate,
        totalAmount: totalAmount,
      );

      // Show success dialog
      await showTransactionSuccessDialog(
        context: context,
        totalAmount: totalAmount,
      );

      // Navigate to home screen
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CarRentHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (navigator.canPop()) navigator.pop();
      showPaymentErrorDialog(context: context, error: e.toString());
    }
  }

  // Confirm booking in Firestore
  static Future<void> _confirmBooking({
    required BuildContext context,
    required double rate,
    required String vehicleId,
    required String vehicleName,
    required String vehicleType,
    required String imageUrl,
    required DateTime pickupDate,
    required DateTime returnDate,
    required double totalAmount,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final rentalDays = returnDate.difference(pickupDate).inDays + 1;

      final bookingData = {
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
        'vehicleType': vehicleType,
        'rate': rate.toString(),
        'imageUrl': imageUrl,
        'pickupDate': Timestamp.fromDate(pickupDate),
        'pickupTime': '${pickupDate.hour}:${pickupDate.minute}',
        'returnDate': Timestamp.fromDate(returnDate),
        'returnTime': '${returnDate.hour}:${returnDate.minute}',
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? 'Anonymous',
        'status': 'Confirmed',
        'createdAt': Timestamp.now(),
        'totalCost': totalAmount,
        'paymentStatus': 'Completed',
        'paymentDate': Timestamp.now(),
        'rentalDuration': rentalDays,
      };

      final batch = FirebaseFirestore.instance.batch();

      final bookingRef =
          FirebaseFirestore.instance.collection('bookings').doc();
      batch.set(bookingRef, bookingData);

      final vehicleRef = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId);
      batch.update(vehicleRef, {'status': 'unavailable'});

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking confirmation failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  // Show transaction success dialog
  static Future<void> showTransactionSuccessDialog({
    required BuildContext context,
    required double totalAmount,
  }) async {
    final formattedAmount = NumberFormat.currency(
      symbol: 'ETB ',
      decimalDigits: 2,
    ).format(totalAmount);

    final formattedTime = DateFormat(
      'yyyy/MM/dd HH:mm:ss',
    ).format(DateTime.now());
    final transactionId = _generateTransactionId();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => TransactionSuccessDialog(
            formattedAmount: formattedAmount,
            formattedTime: formattedTime,
            transactionId: transactionId,
          ),
    );
  }

  // Show payment error dialog
  static void showPaymentErrorDialog({
    required BuildContext context,
    required String error,
  }) {
    showDialog(
      context: context,
      builder: (context) => PaymentErrorDialog(error: error),
    );
  }

  // Generate transaction ID
  static String _generateTransactionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(
      10,
      (index) => chars[rand.nextInt(chars.length)],
    ).join();
  }
}

// Payment Processing Dialog Widget
class PaymentProcessingDialog extends StatelessWidget {
  const PaymentProcessingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Processing payment...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// Transaction Success Dialog Widget
class TransactionSuccessDialog extends StatelessWidget {
  final String formattedAmount;
  final String formattedTime;
  final String transactionId;

  const TransactionSuccessDialog({
    super.key,
    required this.formattedAmount,
    required this.formattedTime,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PaymentSuccessIcon(),
            const SizedBox(height: 16),
            Text(
              'Payment Successful',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              formattedAmount,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            TransactionDetails(
              formattedTime: formattedTime,
              transactionId: transactionId,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Payment Error Dialog Widget
class PaymentErrorDialog extends StatelessWidget {
  final String error;

  const PaymentErrorDialog({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment Failed'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('There was an issue with your payment.'),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: Colors.red)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

// Payment Success Icon Widget
class PaymentSuccessIcon extends StatelessWidget {
  const PaymentSuccessIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
    );
  }
}

// Transaction Details Widget
class TransactionDetails extends StatelessWidget {
  final String formattedTime;
  final String transactionId;

  const TransactionDetails({
    super.key,
    required this.formattedTime,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Transaction Time:', formattedTime),
          const SizedBox(height: 8),
          _buildDetailRow('Transaction Type:', 'Transfer Money'),
          const SizedBox(height: 8),
          _buildDetailRow('Transaction To:', 'iBERAHIM'),
          const SizedBox(height: 8),
          _buildDetailRow('Transaction Number:', transactionId),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
