import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'dashboard_screen.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  final String? developmentOtp;

  const OtpScreen({super.key, required this.mobile, this.developmentOtp});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final TextEditingController _otpController;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController(text: widget.developmentOtp ?? '');
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() => _error = 'Please enter the 6-digit OTP');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.verifyOtp(
        mobile: widget.mobile,
        otp: otp,
      );

      if (!mounted) return;

      if (result['success'] == true && result['token'] != null) {
        final user = result['user'] as Map<String, dynamic>?;

        await AuthStorage.saveSession(
          token: result['token'].toString(),
          mobile: widget.mobile,
          name: user?['name']?.toString(),
          role: user?['role']?.toString(),
        );

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _error = result['message']?.toString() ?? 'Invalid OTP';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to verify OTP';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_outlined, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Enter OTP',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('OTP sent to +91 ${widget.mobile}'),
                if (widget.developmentOtp != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Development OTP: ${widget.developmentOtp}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 28),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: '6-Digit OTP'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('VERIFY'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
