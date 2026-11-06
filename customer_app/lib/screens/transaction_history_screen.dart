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
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _loadTransactions();
  }

  Future<List<Map<String, dynamic>>> _loadTransactions() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login again');
    }

    return ApiService.getCustomerTransactions(token: token);
  }

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _date(dynamic value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final local = parsed.toLocal();

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _refresh() async {
    setState(() {
      _transactionsFuture = _loadTransactions();
    });
    await _transactionsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transactions'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load transactions',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final transactions = snapshot.data ?? [];

            if (transactions.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your completed coupon transactions will appear here.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final item = transactions[index];

                final shopName =
                    item['business_name']?.toString() ?? 'Shop';

                final coupon =
                    item['coupon_number']?.toString() ?? '-';

                final transactionCode =
                    item['transaction_code']?.toString() ?? '-';

                final discountPercent =
                    item['discount_percent']?.toString() ?? '0';

                final originalBill =
                    _money(item['original_bill']);

                final discountAmount =
                    _money(item['discount_amount']);

                final finalAmount =
                    _money(item['final_amount']);

                final status =
                    item['status']?.toString() ?? 'COMPLETED';

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              child: Icon(Icons.storefront),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                shopName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.green.withValues(alpha: .12),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Text(
                          'Coupon: $coupon',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Transaction: $transactionCode',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),

                        const Divider(height: 24),

                        _row('Original Bill', originalBill),
                        _row(
                          'Discount',
                          '$discountAmount ($discountPercent%)',
                        ),
                        _row(
                          'Final Amount',
                          finalAmount,
                          bold: true,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          _date(item['completed_at'] ?? item['created_at']),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
