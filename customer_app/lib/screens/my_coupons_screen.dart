import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> coupons = [];

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Please login again');
      }

      final result = await ApiService.getMyCoupons(token: token);

      if (!mounted) return;

      setState(() {
        coupons = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupCoupons() {
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final coupon in coupons) {
      final key =
          coupon['business_name']?.toString() ??
          coupon['campaign_name']?.toString() ??
          'Shop';

      groups.putIfAbsent(key, () => []).add(coupon);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupCoupons();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text(
          'My Coupons',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF7FF),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCoupons,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 150),
                  Icon(
                    Icons.error_outline,
                    size: 55,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ElevatedButton(
                      onPressed: _loadCoupons,
                      child: const Text('TRY AGAIN'),
                    ),
                  ),
                ],
              )
            : coupons.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 65,
                    color: Color(0xFF80CBC4),
                  ),
                  SizedBox(height: 15),
                  Center(
                    child: Text(
                      'No coupons available yet',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 7),
                  Center(
                    child: Text(
                      'Visit a shop and your 6 scratch coupons will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00695C), Color(0xFF009688)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          color: Colors.white,
                          size: 38,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Scratch Coupons',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Scratch a card to reveal your discount.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...groups.entries.map(
                    (entry) => _ShopCouponSection(
                      shopName: entry.key,
                      coupons: entry.value,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ShopCouponSection extends StatelessWidget {
  final String shopName;
  final List<Map<String, dynamic>> coupons;

  const _ShopCouponSection({required this.shopName, required this.coupons});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFF00796B), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${coupons.length}/6',
                style: const TextStyle(
                  color: Color(0xFF00796B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: coupons.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .82,
            ),
            itemBuilder: (context, index) {
              return ScratchCouponCard(
                coupon: coupons[index],
                slotNumber: index + 1,
              );
            },
          ),
        ],
      ),
    );
  }
}

class ScratchCouponCard extends StatefulWidget {
  final Map<String, dynamic> coupon;
  final int slotNumber;

  const ScratchCouponCard({
    super.key,
    required this.coupon,
    required this.slotNumber,
  });

  @override
  State<ScratchCouponCard> createState() => _ScratchCouponCardState();
}

class _ScratchCouponCardState extends State<ScratchCouponCard> {
  bool revealed = false;

  void _reveal() {
    setState(() {
      revealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final discount = widget.coupon['discount_percent']?.toString() ?? '0';
    final status = widget.coupon['status']?.toString() ?? 'AVAILABLE';

    final used = status == 'USED';

    return GestureDetector(
      onTap: used ? null : _reveal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: revealed
                ? const [Color(0xFF00695C), Color(0xFF009688)]
                : const [Color(0xFF263238), Color(0xFF455A64)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 4),
              color: Colors.black12,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              revealed ? Icons.local_offer : Icons.card_giftcard,
              color: Colors.white,
              size: 42,
            ),
            const SizedBox(height: 10),
            if (revealed) ...[
              Text(
                '$discount% OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'DISCOUNT REVEALED',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .7,
                ),
              ),
            ] else ...[
              const Text(
                'SCRATCH ME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Coupon #${widget.slotNumber}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.touch_app, color: Colors.white70, size: 20),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                used
                    ? 'USED'
                    : revealed
                    ? 'READY TO USE'
                    : 'TAP TO REVEAL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
