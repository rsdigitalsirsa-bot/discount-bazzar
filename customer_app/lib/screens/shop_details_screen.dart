import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import 'shop_coupons_screen.dart';

class ShopDetailsScreen extends StatefulWidget {
  final String businessId;
  final String shopName;
  final String category;
  final String discount;
  final String address;
  final String phone;
  final String openingTime;
  final String closingTime;
  final String shopTier;

  const ShopDetailsScreen({
    super.key,
    this.businessId = '',
    required this.shopName,
    required this.category,
    this.discount = '',
    this.address = 'Address not provided',
    this.phone = 'Phone not provided',
    this.openingTime = '',
    this.closingTime = '',
    this.shopTier = 'SILVER',
  });

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  bool get isGold => widget.shopTier.toUpperCase() == 'GOLD';

  String _timeText() {
    if (widget.openingTime.isEmpty && widget.closingTime.isEmpty) {
      return 'Opening hours not provided';
    }
    if (widget.openingTime.isEmpty) return widget.closingTime;
    if (widget.closingTime.isEmpty) return widget.openingTime;
    return '${widget.openingTime} - ${widget.closingTime}';
  }

  Future<void> _openCoupons() async {
    if (widget.businessId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopCouponsScreen(
          businessId: widget.businessId,
          shopName: widget.shopName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shopName)),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 185,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isGold
                        ? const [Color(0xFF8D6E00), Color(0xFFFFC107)]
                        : const [Color(0xFF455A64), Color(0xFF90A4AE)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: Icon(Icons.storefront, size: 78, color: Colors.white),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.shopName,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _TierBadge(isGold: isGold),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                widget.category.isEmpty ? 'Business' : widget.category,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),

              const SizedBox(height: 22),

              // MAIN COUPON BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: widget.businessId.isEmpty ? null : _openCoupons,
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text(
                    'OPEN COUPONS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Business Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              _DetailRow(
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: widget.address,
              ),

              _DetailRow(
                icon: Icons.access_time,
                title: 'Opening Hours',
                value: _timeText(),
              ),

              _DetailRow(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: widget.phone,
              ),

              const SizedBox(height: 28),

              // REVIEWS & RATINGS
              _ReviewsSection(
                businessId: widget.businessId,
                shopName: widget.shopName,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewsSection extends StatefulWidget {
  final String businessId;
  final String shopName;

  const _ReviewsSection({required this.businessId, required this.shopName});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  late Future<Map<String, dynamic>> reviewsFuture;

  @override
  void initState() {
    super.initState();
    reviewsFuture = ApiService.getBusinessReviews(
      businessId: widget.businessId,
    );
  }

  void _reload() {
    setState(() {
      reviewsFuture = ApiService.getBusinessReviews(
        businessId: widget.businessId,
      );
    });
  }

  Future<String?> _token() async {
    return AuthStorage.getToken();
  }

  Future<void> _writeReview({
    int initialRating = 5,
    String initialText = '',
  }) async {
    int rating = initialRating;
    final controller = TextEditingController(text: initialText);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                initialText.isEmpty ? 'Write a Review' : 'Edit Your Review',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'How was your experience?',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          onPressed: () {
                            setDialogState(() {
                              rating = star;
                            });
                          },
                          icon: Icon(
                            star <= rating ? Icons.star : Icons.star_border,
                            color: Colors.amber.shade700,
                            size: 34,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write your review (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final token = await _token();

                      if (token == null || token.isEmpty) {
                        if (!context.mounted) return;
                        Navigator.pop(context, false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please login to write a review'),
                          ),
                        );
                        return;
                      }

                      await ApiService.saveReview(
                        token: token,
                        businessId: widget.businessId,
                        rating: rating,
                        reviewText: controller.text,
                      );

                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('Unable to save review: $e')),
                      );
                    }
                  },
                  child: const Text('SUBMIT'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (saved == true && mounted) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.businessId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final responseData = snapshot.data ?? {};
        final nestedData = responseData['data'];
        final data = nestedData is Map
            ? Map<String, dynamic>.from(nestedData)
            : <String, dynamic>{};

        final average =
            double.tryParse(data['averageRating']?.toString() ?? '0') ?? 0;
        final count = int.tryParse(data['reviewCount']?.toString() ?? '0') ?? 0;
        final rawReviews = data['reviews'];

        final reviews = rawReviews is List
            ? rawReviews
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
            : <Map<String, dynamic>>[];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Reviews & Ratings',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _writeReview(),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('WRITE'),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Text(
                    average.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < average.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber.shade700,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count review${count == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'No reviews yet. Be the first to review this shop.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                ...reviews.take(5).map((review) {
                  final rating =
                      int.tryParse(review['rating']?.toString() ?? '0') ?? 0;
                  final name =
                      review['customer_name']?.toString() ?? 'Customer';
                  final text = review['review_text']?.toString() ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber.shade700,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                        if (text.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Text(text),
                        ],
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _TierBadge extends StatelessWidget {
  final bool isGold;

  const _TierBadge({required this.isGold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isGold ? const Color(0xFFFFF3CD) : const Color(0xFFECEFF1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isGold ? 'GOLD' : 'SILVER',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: isGold ? const Color(0xFF8D6E00) : const Color(0xFF455A64),
        ),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
