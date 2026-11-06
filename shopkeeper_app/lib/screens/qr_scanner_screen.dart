import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _checking = false;
  String? _message;
  final MobileScannerController _controller = MobileScannerController();

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_checking) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim() ?? '';
      debugPrint('QR DEBUG: rawValue=[$value]');

      if (!value.toUpperCase().contains('COUPON:')) {
        if (mounted) {
          setState(() {
            _message = 'QR detected, but coupon ID format is unexpected.';
          });
        }
        continue;
      }

      final prefixIndex = value.toUpperCase().indexOf('COUPON:');
      final couponId = value.substring(prefixIndex + 'COUPON:'.length).trim();
      if (couponId.isEmpty) continue;

      setState(() {
        _checking = true;
        _message = 'Verifying coupon...';
      });

      await _controller.stop();

      try {
        final token = await AuthStorage.getToken();

        if (token == null || token.isEmpty) {
          throw Exception('Login session not found. Please login again.');
        }

        final response = await http.get(
          Uri.parse(
            '${ApiService.baseUrl}/api/coupons/shopkeeper/verify-qr/$couponId',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;

        if (response.statusCode != 200 || decoded['success'] != true) {
          throw Exception(
            decoded['message']?.toString() ?? 'Coupon verification failed.',
          );
        }

        final data = decoded['data'];
        if (data is! Map || data['coupon_id']?.toString() != couponId) {
          throw Exception('Invalid coupon verification response.');
        }

        if (!mounted) return;
        Navigator.of(context).pop<String>('COUPON:$couponId');
        return;
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _checking = false;
          _message = e.toString().replaceFirst('Exception: ', '');
        });

        await _controller.start();
        return;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Coupon QR'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle flashlight',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _message ??
                  'Customer ke coupon QR code ko camera ke saamne rakhein.',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Coupon backend se verify hone ke baad hi accept hoga.',
              textAlign: TextAlign.center,
            ),
          ),
          if (_checking)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
