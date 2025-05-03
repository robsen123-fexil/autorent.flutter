import 'package:car_rent/pages/userpage/booking/payment/telebirdialog.dart';
import 'package:flutter/material.dart';

class TelebinPaymentScreen extends StatefulWidget {
  final double totalAmount;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String vehicleId;
  final String vehicleName;
  final String vehicleType;
  final String imageUrl;
  final String rate;

  const TelebinPaymentScreen({
    super.key,
    required this.totalAmount,
    required this.pickupDate,
    required this.returnDate,
    required this.vehicleId,
    required this.vehicleName,
    required this.vehicleType,
    required this.imageUrl,
    required this.rate,
  });

  @override
  State<TelebinPaymentScreen> createState() => _TelebinPaymentScreenState();
}

class _TelebinPaymentScreenState extends State<TelebinPaymentScreen> {
  String? selectedMethod;
  final TextEditingController accountController = TextEditingController();
  final TextEditingController accountHolderController = TextEditingController();
  final TextEditingController phoneOrAccountController =
      TextEditingController();

  final Map<String, String> paymentAccounts = {
    'telebirr': '+2519001234',
    'mpesa': '+251700123563',
    'cbe': '100011223456',
    'awash': '0462820924',
  };

  final Map<String, String> prefixRules = {
    'telebirr': '+2519',
    'mpesa': '+2517',
    'cbe': '1000',
    'awash': '056',
  };

  bool isValidPaymentInput(String method, String input) {
    final expectedPrefix = prefixRules[method];
    return expectedPrefix != null && input.startsWith(expectedPrefix);
  }

  @override
  void dispose() {
    accountController.dispose();
    accountHolderController.dispose();
    phoneOrAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vatAmount = widget.totalAmount * 0.15;
    final subtotal = widget.totalAmount - vatAmount;
    final totalDays =
        widget.returnDate.difference(widget.pickupDate).inDays + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Complete your rental payment below',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Order Summary
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildOrderItem('Vehicle Rent ($totalDays days)'),
              _buildOrderItem('${subtotal.toStringAsFixed(2)} ETB'),
              _buildOrderItem('VAT (15%)'),
              _buildOrderItem('${vatAmount.toStringAsFixed(2)} ETB'),
              const Divider(thickness: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.totalAmount.toStringAsFixed(2)} ETB',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Payment Form
              const Text(
                'Phone Number / Account',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: accountController,
                enabled: false,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Account Holder Name', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: accountHolderController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter account holder name',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Phone Number/Account Number',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                onChanged: (value) {
                  if (selectedMethod != null &&
                      !isValidPaymentInput(selectedMethod!, value)) {
                    // Live validation hint
                  }
                },
                controller: phoneOrAccountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter Your Phone/ Bank Account',
                ),
              ),
              const SizedBox(height: 24),

              // Payment Methods
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildPaymentOption('telebirr'),
                  _buildPaymentOption('mpesa'),
                  _buildPaymentOption('cbe'),
                  _buildPaymentOption('awash'),
                ],
              ),
              const SizedBox(height: 32),

              // Pay Now Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handlePayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePayment() {
    if (selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method.")),
      );
      return;
    }

    if (accountHolderController.text.trim().isEmpty ||
        phoneOrAccountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    final phoneOrAccount = phoneOrAccountController.text.trim();

    if (!isValidPaymentInput(selectedMethod!, phoneOrAccount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid input. Must start with ${prefixRules[selectedMethod!]}.',
          ),
        ),
      );
      return;
    }

    PaymentService.processPayment(
      context: context,
      totalAmount: widget.totalAmount,
      vehicleId: widget.vehicleId,
      rate: double.parse(widget.rate),
      vehicleName: widget.vehicleName,
      vehicleType: widget.vehicleType,
      imageUrl: widget.imageUrl,
      pickupDate: widget.pickupDate,
      returnDate: widget.returnDate,
    );
  }

  Widget _buildOrderItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildPaymentOption(String key) {
    final isSelected = selectedMethod == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = key;
          accountController.text = paymentAccounts[key] ?? '';
        });
      },
      child: Container(
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.green : Colors.grey),
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: AssetImage('assets/$key.jpeg'),
            fit: BoxFit.cover,
            colorFilter:
                isSelected
                    ? const ColorFilter.mode(Colors.black45, BlendMode.darken)
                    : null,
          ),
        ),
        alignment: Alignment.center,
        child:
            isSelected
                ? const Icon(Icons.check_circle, color: Colors.white)
                : const SizedBox.shrink(),
      ),
    );
  }
}
