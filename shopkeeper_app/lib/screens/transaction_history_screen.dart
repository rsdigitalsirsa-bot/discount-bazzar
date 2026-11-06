import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends State<TransactionHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login again');
    }

    return ApiService.getShopkeeperTransactions(token: token);
  }

  String money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String text(dynamic value) {
    if (value == null) return '';
    final result = value.toString().trim();
    if (result.isEmpty ||
        result.toLowerCase() == 'undefined' ||
        result.toLowerCase() == 'null') {
      return '';
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text('Unable to load transactions'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _future = _load();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const Center(
              child: Text('No transactions yet'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _load();
              });
              await _future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final t = transactions[index];

                final status =
                    text(t['status']).isEmpty ? 'COMPLETED' : text(t['status']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_outlined),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                text(t['business_name']).isEmpty
                                    ? 'Transaction'
                                    : text(t['business_name']),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(status),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text('Transaction: ${text(t['transaction_code'])}'),
                        Text(
                          'Coupon: ${text(t['coupon_number']).isNotEmpty ? text(t['coupon_number']) : text(t['coupon_id'])}',
                        ),

                        if (text(t['customer_mobile']).isNotEmpty)
                          Text('Customer: ${text(t['customer_mobile'])}'),

                        const SizedBox(height: 10),

                        _row(
                          'Original Bill',
                          money(t['original_bill']),
                        ),

                        _row(
                          'Discount',
                          '${money(t['discount_amount'])} (${text(t['discount_percent'])}%)',
                        ),

                        _row(
                          'Final Amount',
                          money(t['final_amount']),
                          bold: true,
                        ),

                        if (text(t['verification_code']).isNotEmpty)
                          _row(
                            'Verification Code',
                            text(t['verification_code']),
                          ),
                        if (text(t['created_at']).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            text(t['created_at']),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _row(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
