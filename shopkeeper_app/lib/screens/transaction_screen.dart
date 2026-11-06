import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class TransactionScreen extends StatefulWidget {
  final String couponId;
  final String couponNumber;
  final String customerId;
  final double discountPercent;
  final double minBill;
  final String businessName;

  const TransactionScreen({
    super.key,
    required this.couponId,
    required this.couponNumber,
    required this.customerId,
    required this.discountPercent,
    required this.minBill,
    required this.businessName,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _billController = TextEditingController();
  final _verificationController = TextEditingController();

  bool _calculating = false;
  bool _confirming = false;

  Map<String, dynamic>? _calculation;

  @override
  void dispose() {
    _billController.dispose();
    _verificationController.dispose();
    super.dispose();
  }

  double? get _billAmount => double.tryParse(_billController.text.trim());

  Future<void> _calculate() async {
    FocusScope.of(context).unfocus();

    final bill = _billAmount;

    if (bill == null || bill < 0) {
      _showMessage('Please enter a valid bill amount');
      return;
    }

    if (bill < widget.minBill) {
      _showMessage(
        'Minimum bill amount is ₹${widget.minBill.toStringAsFixed(2)}',
      );
      return;
    }

    try {
      setState(() {
        _calculating = true;
        _calculation = null;
      });

      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found');
      }

      final response = await ApiService.calculateTransaction(
        token: token,
        couponId: widget.couponId,
        billAmount: bill,
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(
          response['message']?.toString() ?? 'Failed to calculate transaction',
        );
      }

      setState(() {
        _calculation = Map<String, dynamic>.from(response['data'] ?? {});
        _calculating = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _calculating = false);
      _showMessage(e.toString());
    }
  }

  Future<void> _confirm() async {
    if (_calculation == null || _confirming) return;

    final bill = _billAmount;

    if (bill == null) {
      _showMessage('Invalid bill amount');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final discount = numberValue(_calculation?['discountAmount']);
        final finalAmount = numberValue(_calculation?['finalAmount']);

        return AlertDialog(
          title: const Text('Confirm Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Coupon: ${widget.couponNumber}'),
              const SizedBox(height: 8),
              Text('Bill: ₹${bill.toStringAsFixed(2)}'),
              Text('Discount: ₹${discount.toStringAsFixed(2)}'),
              Text(
                'Final Amount: ₹${finalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              const Text(
                'Customer Verification Code',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _verificationController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit code',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the code provided by the customer.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                'After confirmation this coupon will be marked USED.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final code = _verificationController.text.trim();

                if (!RegExp(r'^\d{4}$').hasMatch(code)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter the 4-digit verification code',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(context, true);
              },
              child: const Text('CONFIRM'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() => _confirming = true);

      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found');
      }

      final response = await ApiService.confirmTransaction(
        token: token,
        couponId: widget.couponId,
        billAmount: bill,
        verificationCode: _verificationController.text.trim(),
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(
          response['message']?.toString() ?? 'Transaction confirmation failed',
        );
      }

      final data = Map<String, dynamic>.from(response['data'] ?? {});

      final finalAmount = numberValue(data['finalAmount']);

      setState(() => _confirming = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle, size: 60, color: Colors.green),
            title: const Text('Transaction Completed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Coupon ${widget.couponNumber}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text('Coupon marked as USED.'),
                const SizedBox(height: 12),
                Text(
                  'Pay ₹${finalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('DONE'),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _confirming = false);
      _showMessage(e.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final calculation = _calculation;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Coupon')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CLAIMED COUPON',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.couponNumber,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.businessName),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.discountPercent}% OFF',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Minimum bill ₹${widget.minBill.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Customer Bill Amount',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _billController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: 'Enter bill amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) {
                if (_calculation != null) {
                  setState(() => _calculation = null);
                }
              },
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _calculating ? null : _calculate,
                icon: _calculating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.calculate),
                label: Text(
                  _calculating ? 'CALCULATING...' : 'CALCULATE DISCOUNT',
                ),
              ),
            ),

            if (calculation != null) ...[
              const SizedBox(height: 24),

              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _summaryRow(
                        'Original Bill',
                        numberValue(calculation['originalBill']),
                      ),
                      _summaryRow(
                        'Discount',
                        numberValue(calculation['discountAmount']),
                        valueSuffix:
                            ' (${numberValue(calculation['discountPercent']).toStringAsFixed(2)}%)',
                      ),
                      const Divider(height: 24),
                      _summaryRow(
                        'FINAL AMOUNT',
                        numberValue(calculation['finalAmount']),
                        large: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _confirming ? null : _confirm,
                  icon: _confirming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified),
                  label: Text(
                    _confirming ? 'CONFIRMING...' : 'CONFIRM & USE COUPON',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double value, {
    String valueSuffix = '',
    bool large = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: large ? 17 : 14,
                fontWeight: large ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}$valueSuffix',
            style: TextStyle(
              fontSize: large ? 20 : 15,
              fontWeight: large ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

double numberValue(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
