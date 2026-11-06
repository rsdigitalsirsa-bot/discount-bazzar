import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'qr_scanner_screen.dart';
import 'transaction_screen.dart';

class ClaimedCouponsScreen extends StatefulWidget {
  const ClaimedCouponsScreen({super.key});

  @override
  State<ClaimedCouponsScreen> createState() => _ClaimedCouponsScreenState();
}

class _ClaimedCouponsScreenState extends State<ClaimedCouponsScreen> {
  bool _loading = true;
  bool _scanning = false;
  String? _error;
  List<Map<String, dynamic>> _coupons = [];

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found. Please login again.');
      }

      final result = await ApiService.getClaimedCoupons(token: token);

      if (!mounted) return;

      setState(() {
        _coupons = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _scanCouponQr() async {
    if (_loading || _scanning) return;

    setState(() => _scanning = true);

    try {
      final scannedValue = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );

      if (!mounted || scannedValue == null) return;
      debugPrint('SCANNED QR VALUE: "$scannedValue"');
      final scanned = scannedValue.trim();
      final upperScanned = scanned.toUpperCase();

      final prefixIndex = upperScanned.indexOf('COUPON:');
      if (prefixIndex == -1) {
        _showMessage('Invalid QR: coupon ID not found.');
        return;
      }

      final couponId = scanned.substring(prefixIndex + 'COUPON:'.length).trim();

      if (couponId.isEmpty) {
        _showMessage('Coupon ID is missing.');
        return;
      }

      if (couponId.isEmpty) {
        _showMessage('Coupon ID is missing.');
        return;
      }

      // Reload the latest claimed coupons before matching.
      await _loadCoupons();

      if (!mounted) return;

      final matches = _coupons.where(
        (coupon) => coupon['coupon_id']?.toString().trim() == couponId,
      );

      if (matches.isEmpty) {
        _showMessage(
          'Coupon not found in this shop. Check the shop and coupon status.',
        );
        return;
      }

      await _openTransaction(matches.first);
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Could not process QR: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  Future<void> _openTransaction(Map<String, dynamic> coupon) async {
    final couponId = coupon['coupon_id']?.toString() ?? '';

    if (couponId.isEmpty) {
      _showMessage('Coupon ID is missing.');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionScreen(
          couponId: couponId,
          couponNumber: coupon['coupon_number']?.toString() ?? 'COUPON',
          customerId: coupon['customer_id']?.toString() ?? '',
          discountPercent: _number(coupon['discount_percent']),
          minBill: _number(coupon['min_bill']),
          businessName: coupon['business_name']?.toString() ?? '',
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadCoupons();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claimed Coupons'),
        actions: [
          IconButton(
            onPressed: (_loading || _scanning) ? null : _scanCouponQr,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR',
          ),
          IconButton(
            onPressed: (_loading || _scanning) ? null : _loadCoupons,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : _coupons.isEmpty
          ? _emptyView()
          : RefreshIndicator(
              onRefresh: _loadCoupons,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _coupons.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _couponCard(_coupons[index]),
              ),
            ),
    );
  }

  Widget _couponCard(Map<String, dynamic> coupon) {
    final couponNumber = coupon['coupon_number']?.toString() ?? 'COUPON';
    final discount = _number(coupon['discount_percent']);
    final minBill = _number(coupon['min_bill']);
    final customerId = coupon['customer_id']?.toString() ?? '';
    final claimedAt = coupon['claimed_at']?.toString() ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: Icon(Icons.local_offer, color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        couponNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        coupon['business_name']?.toString() ?? 'Your Shop',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'CLAIMED',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _info('DISCOUNT', '${discount.toStringAsFixed(2)}%'),
                ),
                Expanded(
                  child: _info('MIN BILL', '₹${minBill.toStringAsFixed(2)}'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Customer: $customerId',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (claimedAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Claimed: $claimedAt',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _scanning ? null : () => _openTransaction(coupon),
                icon: const Icon(Icons.receipt_long),
                label: const Text('VERIFY & PROCESS COUPON'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Claimed Coupons',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'When a customer claims a coupon from your shop, '
              'it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadCoupons,
              icon: const Icon(Icons.refresh),
              label: const Text('REFRESH'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60),
            const SizedBox(height: 14),
            Text(_error ?? 'Something went wrong', textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: _loadCoupons, child: const Text('RETRY')),
          ],
        ),
      ),
    );
  }
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
