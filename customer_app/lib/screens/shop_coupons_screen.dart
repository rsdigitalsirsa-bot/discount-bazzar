import 'package:flutter/material.dart';
import 'package:flutter_scratch_card/flutter_scratch_card.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class ShopCouponsScreen extends StatefulWidget {
  final String businessId;
  final String shopName;

  const ShopCouponsScreen({
    super.key,
    required this.businessId,
    required this.shopName,
  });

  @override
  State<ShopCouponsScreen> createState() => _ShopCouponsScreenState();
}

class _ShopCouponsScreenState extends State<ShopCouponsScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> coupons = [];

  @override
  void initState() {
    super.initState();
    _openCoupons();
  }

  Future<void> _openCoupons() async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found');
      }

      final result = await ApiService.openShopCoupons(
        token: token,
        businessId: widget.businessId,
      );

      if (!mounted) return;

      setState(() {
        coupons = result.take(6).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  int _activeIndex() {
    for (int i = 0; i < coupons.length; i++) {
      final status =
          coupons[i]['status']?.toString().toUpperCase() ?? 'AVAILABLE';

      if (status != 'CLAIMED' && status != 'USED') {
        return i;
      }
    }

    return coupons.length;
  }

  void _couponClaimed(int index) {
    if (!mounted) return;

    setState(() {
      coupons[index] = {...coupons[index], 'status': 'CLAIMED'};
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex();

    return Scaffold(
      appBar: AppBar(title: Text(widget.shopName)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _ErrorView(message: error!, onRetry: _openCoupons)
          : coupons.length != 6
          ? _NoCouponsView(onRetry: _openCoupons)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '6 COUPONS',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeIndex < 6
                        ? 'Scratch Coupon ${activeIndex + 1} first. Claim it to unlock the next coupon.'
                        : 'All 6 coupons have been claimed.',
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: coupons.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      final status =
                          coupon['status']?.toString().toUpperCase() ??
                          'AVAILABLE';

                      final isClaimed = status == 'CLAIMED' || status == 'USED';

                      final isActive = index == activeIndex;

                      return _ScratchCouponCard(
                        key: ValueKey(
                          '${coupon['id'] ?? coupon['coupon_number']}-$status',
                        ),
                        coupon: coupon,
                        index: index,
                        enabled: isActive && !isClaimed,
                        claimed: isClaimed,
                        onClaimed: () => _couponClaimed(index),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _ScratchCouponCard extends StatefulWidget {
  final Map<String, dynamic> coupon;
  final int index;
  final bool enabled;
  final bool claimed;
  final VoidCallback onClaimed;

  const _ScratchCouponCard({
    super.key,
    required this.coupon,
    required this.index,
    required this.enabled,
    required this.claimed,
    required this.onClaimed,
  });

  @override
  State<_ScratchCouponCard> createState() => _ScratchCouponCardState();
}

class _ScratchCouponCardState extends State<_ScratchCouponCard> {
  bool revealed = false;
  bool claiming = false;

  Future<void> _claimNow() async {
    if (claiming || !revealed || widget.claimed) return;

    try {
      setState(() {
        claiming = true;
      });

      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found');
      }

      final couponId = widget.coupon['id']?.toString() ?? '';

      if (couponId.isEmpty) {
        throw Exception('Coupon ID not found');
      }

      final response = await ApiService.claimCoupon(
        token: token,
        couponId: couponId,
      );

      if (!mounted) return;

      if (response['success'] != true) {
        throw Exception(
          response['message']?.toString() ?? 'Failed to claim coupon',
        );
      }

      final data = response['data'];
      final claim = data is Map ? data['claim'] : null;
      final verificationCode = claim is Map
          ? claim['verification_code']?.toString() ?? ''
          : '';

      setState(() {
        claiming = false;
      });

      widget.onClaimed();

      if (mounted && verificationCode.isNotEmpty) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Coupon Claimed Successfully'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Scan this QR at the shop',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  QrImageView(
                    data: 'COUPON:${widget.coupon['id']}',
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Verification Code',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF00695C), width: 2),
                    ),
                    child: Text(
                      verificationCode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Share this code with the shopkeeper to complete your transaction.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon claimed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        claiming = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final discount = widget.coupon['discount_percent']?.toString() ?? '0';

    final couponNumber =
        widget.coupon['coupon_number']?.toString() ?? 'DB-COUPON';

    if (widget.claimed) {
      return _claimedCard(discount: discount, couponNumber: couponNumber);
    }

    if (!widget.enabled) {
      return _lockedCard(discount: discount, couponNumber: couponNumber);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 5),
            color: Colors.black12,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 270,
            child: ScratchCard(
              theme: ScratchCardTheme.premium(),
              brush: ScratchBrush.soft(size: 35),
              onComplete: () {
                if (mounted) {
                  setState(() {
                    revealed = true;
                  });
                }
              },
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00695C), Color(0xFF009688)],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_offer,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '$discount% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coupon #${widget.index + 1}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          couponNumber,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (revealed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    '$discount% OFF UNLOCKED',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: claiming ? null : _claimNow,
                      icon: claiming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.confirmation_number),
                      label: Text(
                        claiming ? 'CLAIMING...' : 'CLAIM NOW',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _claimedCard({
    required String discount,
    required String couponNumber,
  }) {
    final couponId = widget.coupon['id']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 52),
          const SizedBox(height: 10),
          Text(
            'Coupon ${widget.index + 1} Claimed',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text('$discount% OFF'),
          const SizedBox(height: 4),
          Text(
            couponNumber,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          if (couponId.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Show this QR code to the shopkeeper',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: 'COUPON:$couponId',
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The shopkeeper must scan and verify this coupon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lockedCard({required String discount, required String couponNumber}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          'Coupon ${widget.index + 1} Locked',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('RETRY')),
          ],
        ),
      ),
    );
  }
}

class _NoCouponsView extends StatelessWidget {
  final VoidCallback onRetry;

  const _NoCouponsView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text(
              '6 coupons are not available right now.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('RETRY')),
          ],
        ),
      ),
    );
  }
}
