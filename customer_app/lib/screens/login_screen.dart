import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final mobileController = TextEditingController();
  bool loading = false;

  Future<void> sendOtp() async {
    final mobile = mobileController.text.trim();

    if (!RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10 digit mobile number'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final result = await ApiService.requestOtp(mobile);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            mobile: mobile,
            developmentOtp: result['developmentOtp']?.toString(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.local_offer,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'DISCOUNT BAZZAR',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Discover Local Deals & Save More',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 45),

                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    prefixText: '+91 ',
                    labelText: 'Mobile Number',
                    hintText: 'Enter 10 digit mobile number',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : sendOtp,
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'SEND OTP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }
}
