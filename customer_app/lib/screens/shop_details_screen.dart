import 'package:flutter/material.dart';

import 'coupon_details_screen.dart';

class ShopDetailsScreen extends StatelessWidget {
  final String shopName;
  final String category;
  final String discount;

  const ShopDetailsScreen({
    super.key,
    required this.shopName,
    required this.category,
    required this.discount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
        actions: const [Icon(Icons.favorite_border), SizedBox(width: 16)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00695C), Color(0xFF009688)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Icon(Icons.storefront, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              shopName,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              category,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoChip(icon: Icons.star, text: '4.7 Rating'),
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.location_on_outlined, text: '1.2 km'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Business Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const _DetailRow(
              icon: Icons.location_on_outlined,
              title: 'Address',
              value: 'Main Market, Your City',
            ),
            const _DetailRow(
              icon: Icons.access_time,
              title: 'Opening Hours',
              value: '10:00 AM - 8:00 PM',
            ),
            const _DetailRow(
              icon: Icons.phone_outlined,
              title: 'Phone',
              value: '+91 XXXXX XXXXX',
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Coupon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: const Color(0xFFE0F2F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 27,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.local_offer, color: Color(0xFF00796B)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            discount,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00796B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Available now • Claim your coupon',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CouponDetailsScreen(
                              shopName: shopName,
                              discount: discount,
                            ),
                          ),
                        );
                      },
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00796B)),
          const SizedBox(width: 5),
          Text(text),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00796B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
