import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final mobile = _mobileController.text.trim();

    if (mobile.length != 10) {
      setState(() => _error = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.requestOtp(mobile: mobile);

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              mobile: mobile,
              developmentOtp: result['developmentOtp']?.toString(),
            ),
          ),
        );
      } else {
        setState(() {
          _error = result['message']?.toString() ?? 'Unable to send OTP';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to connect to server';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 64),
                        const SizedBox(height: 18),
                        Text(
                          'DISCOUNT BAZZAR',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Grow Your Business With Smart Discounts.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 55),
                  Text(
                    'Shopkeeper Login',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text('Enter your mobile number to continue.'),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixText: '+91  ',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
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
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _sendOtp,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('SEND OTP'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
