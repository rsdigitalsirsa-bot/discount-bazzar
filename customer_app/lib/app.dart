import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class DiscountBazzarApp extends StatelessWidget {
  const DiscountBazzarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Discount Bazzar',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
