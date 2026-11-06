import 'package:flutter/material.dart';

import '../services/auth_storage.dart';
import '../services/api_service.dart';
import 'business_registration_screen.dart';
import 'manage_business_screen.dart';
import 'claimed_coupons_screen.dart';
import 'login_screen.dart';
import 'transaction_history_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _mobile;
  String? _name;
  String? _businessName;
  String? _verificationStatus;
  int _totalCoupons = 0;
  int _usedCoupons = 0;
  int _todayTransactions = 0;
  double _todayDiscount = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _loadUnreadNotifications();
  }

  Future<void> _loadUnreadNotifications() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) return;

    try {
      final count = await ApiService.getUnreadNotificationCount(
        token: token,
      );

      if (!mounted) return;

      setState(() {
        _unreadNotifications = count;
      });
    } catch (_) {
      // Keep dashboard usable if notification count fails.
    }
  }

  Future<void> _loadSession() async {
    final mobile = await AuthStorage.getMobile();
    final name = await AuthStorage.getName();
    final token = await AuthStorage.getToken();

    String? businessName;

    if (token != null && token.isNotEmpty) {
      try {
        final result = await ApiService.getMyBusinessStatus(token: token);

        if (result['success'] == true) {
          final data = result['data'] as Map<String, dynamic>?;

          businessName = data?['businessName']?.toString();
          _verificationStatus = data?['verificationStatus']?.toString();
        }
      } catch (_) {
        // Keep dashboard usable if status request fails.
      }
    }

    if (token != null && token.isNotEmpty) {
      try {
        final stats = await ApiService.getDashboardStats(token: token);

        if (stats['success'] == true) {
          final data = stats['data'] as Map<String, dynamic>?;

          _totalCoupons = int.tryParse(
                '${data?['totalCoupons'] ?? 0}',
              ) ??
              0;

          _usedCoupons = int.tryParse(
                '${data?['usedCoupons'] ?? 0}',
              ) ??
              0;

          _todayTransactions = int.tryParse(
                '${data?['todayTransactions'] ?? 0}',
              ) ??
              0;

          _todayDiscount = double.tryParse(
                '${data?['todayDiscount'] ?? 0}',
              ) ??
              0;
        }
      } catch (_) {
        // Keep dashboard usable if stats request fails.
      }
    }

    if (!mounted) return;

    setState(() {
      _mobile = mobile;
      _name = name;
      _businessName = businessName;
    });
  }

  Future<void> _logout() async {
    await AuthStorage.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openBusinessRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BusinessRegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessName =
        (_businessName == null || _businessName!.trim().isEmpty)
        ? ((_name == null || _name!.trim().isEmpty) ? 'Your Business' : _name!)
        : _businessName!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopkeeper Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'DISCOUNT BAZZAR',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(businessName, style: Theme.of(context).textTheme.titleLarge),
          if (_mobile != null) ...[
            const SizedBox(height: 4),
            Text('+91 $_mobile'),
          ],
          const SizedBox(height: 24),

          _DashboardCard(
            icon: Icons.local_offer_outlined,
            title: 'Total Coupons',
            value: '$_totalCoupons',
          ),
          _DashboardCard(
            icon: Icons.check_circle_outline,
            title: 'Coupons Used',
            value: '$_usedCoupons',
          ),
          _DashboardCard(
            icon: Icons.receipt_long_outlined,
            title: "Today's Transactions",
            value: '$_todayTransactions',
          ),
          _DashboardCard(
            icon: Icons.currency_rupee,
            title: "Today's Discount",
            value: '₹${_todayDiscount.toStringAsFixed(0)}',
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClaimedCouponsScreen(),
                  ),
                ).then((_) {
                  if (mounted) {
                    _loadSession();
                  }
                });
              },
              icon: const Icon(Icons.local_offer),
              label: const Text('MANAGE COUPONS'),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('TRANSACTION HISTORY'),
            ),
          ),


          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );

                _loadUnreadNotifications();
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _unreadNotifications > 99
                              ? '99+'
                              : '$_unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: const Text('NOTIFICATIONS'),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(height: 52, child: _buildBusinessActionButton()),
        ],
      ),
    );
  }

  Widget _buildBusinessActionButton() {
    final status = _verificationStatus?.toUpperCase();

    if (status == 'VERIFIED') {
      return FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageBusinessScreen()),
          );
        },
        icon: const Icon(Icons.verified_outlined),
        label: const Text('MANAGE MY BUSINESS'),
      );
    }

    if (status == 'PENDING') {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_top),
        label: const Text('VERIFICATION PENDING'),
      );
    }

    if (status == 'REJECTED') {
      return FilledButton.icon(
        onPressed: _openBusinessRegistration,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('RESUBMIT BUSINESS'),
      );
    }

    return FilledButton.icon(
      onPressed: _openBusinessRegistration,
      icon: const Icon(Icons.storefront_outlined),
      label: const Text('SET UP MY BUSINESS'),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
