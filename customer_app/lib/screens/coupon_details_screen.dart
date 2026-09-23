import 'package:flutter/material.dart';

class CouponDetailsScreen extends StatefulWidget {
  final String shopName;
  final String discount;

  const CouponDetailsScreen({
    super.key,
    required this.shopName,
    required this.discount,
  });

  @override
  State<CouponDetailsScreen> createState() => _CouponDetailsScreenState();
}

class _CouponDetailsScreenState extends State<CouponDetailsScreen> {
  bool claimed = false;

  void claimCoupon() {
    setState(() {
      claimed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coupon claimed successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coupon Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00695C), Color(0xFF009688)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(Icons.local_offer, color: Colors.white, size: 55),
                  const SizedBox(height: 14),
                  Text(
                    widget.discount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.shopName,
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Coupon Terms',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            const _Rule(text: 'Valid on eligible purchases'),
            const _Rule(text: 'Minimum bill amount may apply'),
            const _Rule(text: 'One coupon per eligible transaction'),
            const _Rule(text: 'Coupon cannot be reused after completion'),
            const _Rule(text: 'Discount is calculated automatically'),
            const SizedBox(height: 24),
            if (claimed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 52),
                    SizedBox(height: 10),
                    Text(
                      'Coupon Claimed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Show the coupon verification code to the shopkeeper.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: claimCoupon,
                  icon: const Icon(Icons.confirmation_number),
                  label: const Text(
                    'CLAIM COUPON',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final String text;

  const _Rule({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 19,
            color: Color(0xFF00796B),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
