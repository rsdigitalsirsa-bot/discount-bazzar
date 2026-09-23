import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  final String? developmentOtp;

  const OtpScreen({
    super.key,
    required this.mobile,
    this.developmentOtp,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpController = TextEditingController();
  bool loading = false;

  Future<void> verify() async {
    if (otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6 digit OTP')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await ApiService.verifyOtp(
        widget.mobile,
        otpController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 35),

            const Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'OTP sent to +91 ${widget.mobile}',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
            ),

            if (widget.developmentOtp != null) ...[
              const SizedBox(height: 10),
              Text(
                'Development OTP: ${widget.developmentOtp}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 25),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : verify,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'VERIFY & CONTINUE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}
