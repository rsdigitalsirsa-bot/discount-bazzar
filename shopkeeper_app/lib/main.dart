import 'package:flutter/material.dart';

import 'services/auth_storage.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const DiscountBazzarShopkeeperApp());
}

class DiscountBazzarShopkeeperApp extends StatelessWidget {
  const DiscountBazzarShopkeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discount Bazzar - Shopkeeper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _StartScreen(),
    );
  }
}

class _StartScreen extends StatefulWidget {
  const _StartScreen();

  @override
  State<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<_StartScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthStorage.isLoggedIn(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data == true
            ? const DashboardScreen()
            : const LoginScreen();
      },
    );
  }
}
