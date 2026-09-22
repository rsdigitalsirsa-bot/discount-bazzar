import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

class DiscountBazzarApp extends StatelessWidget {
  const DiscountBazzarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Discount Bazzar',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F766E),
      ),
      home: const LoginScreen(),
    );
  }
}
