import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

class DiscountBazzarApp extends StatelessWidget {
  const DiscountBazzarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discount Bazzar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
