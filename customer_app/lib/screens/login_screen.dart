import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'DISCOUNT BAZZAR',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Find deals. Save more.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              const Text(
                'Login with Mobile Number',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {},
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('SEND OTP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
