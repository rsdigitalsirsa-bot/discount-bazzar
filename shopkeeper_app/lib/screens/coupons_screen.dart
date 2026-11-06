import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _minBillController = TextEditingController();
  final _termsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _creating = false;
  bool _loadingCampaigns = true;

  List<Map<String, dynamic>> campaigns = [];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxDiscountController.dispose();
    _minBillController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _loadingCampaigns = true;
    });

    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found');
      }

      final response = await ApiService.getMyCouponCampaigns(
        token: token,
      );

      final data = response['data'];

      if (data is List) {
        campaigns = data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (data is Map && data['campaigns'] is List) {
        campaigns = (data['campaigns'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        campaigns = [];
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load coupons: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingCampaigns = false;
        });
      }
    }
  }

  Future<void> _selectDate({required bool start}) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate:
          start ? (_startDate ?? now) : (_endDate ?? _startDate ?? now),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      if (start) {
        _startDate = picked;

        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatApiDate(DateTime date, {bool endOfDay = false}) {
    final value = endOfDay
        ? DateTime(
            date.year,
            date.month,
            date.day,
            23,
            59,
            59,
          )
        : DateTime(
            date.year,
            date.month,
            date.day,
            0,
            0,
            0,
          );

    return value.toIso8601String();
  }

  double? _maximumDiscount() {
    final value = double.tryParse(
      _maxDiscountController.text.trim(),
    );

    return value;
  }

  double? _discount60() {
    final max = _maximumDiscount();
    if (max == null) return null;
    return double.parse((max * 0.60).toStringAsFixed(2));
  }

  double? _discount80() {
    final max = _maximumDiscount();
    if (max == null) return null;
    return double.parse((max * 0.80).toStringAsFixed(2));
  }

  String _discountText(double? value) {
    if (value == null) return '--';

    if (value == value.roundToDouble()) {
      return '${value.toInt()}%';
    }

    return '${value.toStringAsFixed(2)}%';
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
        ),
      );
      return;
    }

    final maxDiscount = _maximumDiscount();

    if (maxDiscount == null ||
        maxDiscount <= 0 ||
        maxDiscount > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum discount must be between 1% and 100%',
          ),
        ),
      );
      return;
    }

    setState(() {
      _creating = true;
    });

    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found');
      }

      final minimumBill =
          double.tryParse(_minBillController.text.trim()) ?? 0;

      final response = await ApiService.createCouponCampaign(
        token: token,
        data: {
          'name': _nameController.text.trim(),
          'maxDiscountPercent': maxDiscount,
          'validityStart': _formatApiDate(_startDate!),
          'validityEnd': _formatApiDate(
            _endDate!,
            endOfDay: true,
          ),
          'minBill': minimumBill,
          'terms': _termsController.text.trim(),
        },
      );

      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'Failed to create coupon campaign',
        );
      }

      if (!mounted) return;

      _nameController.clear();
      _maxDiscountController.clear();
      _minBillController.clear();
      _termsController.clear();

      setState(() {
        _startDate = null;
        _endDate = null;
      });

      await _loadCampaigns();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            '6 scratch coupons created successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  dynamic _value(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (item[key] != null) return item[key];
    }
    return null;
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _decoration(
    String hint, {
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _couponPreview() {
    final max = _maximumDiscount();
    final d60 = _discount60();
    final d80 = _discount80();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade700,
            Colors.indigo.shade400,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                '6 SCRATCH COUPONS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Coupons will be generated automatically',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _couponPreviewCard(
                _discountText(d60),
                '2 Coupons',
              ),
              const SizedBox(width: 8),
              _couponPreviewCard(
                _discountText(d80),
                '2 Coupons',
              ),
              const SizedBox(width: 8),
              _couponPreviewCard(
                _discountText(max),
                '2 Coupons',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '60% of maximum  •  80% of maximum  •  100% of maximum',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _couponPreviewCard(
    String discount,
    String quantity,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white24,
          ),
        ),
        child: Column(
          children: [
            Text(
              discount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              quantity,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: ${value ?? 0}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _campaignCard(Map<String, dynamic> campaign) {
    final name = _value(
      campaign,
      ['name', 'campaign_name'],
    );

    final maxDiscount = _value(
      campaign,
      ['max_discount', 'maxDiscount'],
    );

    final total = _value(
      campaign,
      ['total_coupons', 'totalCoupons'],
    );

    final available = _value(
      campaign,
      ['available_coupons', 'availableCoupons'],
    );

    final claimed = _value(
      campaign,
      ['claimed_coupons', 'claimedCoupons'],
    );

    final used = _value(
      campaign,
      ['used_coupons', 'usedCoupons'],
    );

    final start = _value(
      campaign,
      ['validity_start', 'validityStart'],
    );

    final end = _value(
      campaign,
      ['validity_end', 'validityEnd'],
    );

    final active = campaign['is_active'] == true ||
        campaign['isActive'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name?.toString() ?? 'Offer',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.green.shade50
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    active ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: active
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Maximum Discount: ${maxDiscount ?? 0}%',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _statChip('Total', total),
                _statChip('Available', available),
                _statChip('Claimed', claimed),
                _statChip('Used', used),
              ],
            ),
            if (start != null || end != null) ...[
              const SizedBox(height: 10),
              Text(
                'Validity: ${start ?? '-'} → ${end ?? '-'}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Coupon Offer',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set your maximum discount. The system will automatically create 6 scratch coupons.',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          _fieldLabel('Offer / Campaign Name'),
          TextFormField(
            controller: _nameController,
            decoration: _decoration(
              'Example: Welcome Offer',
              icon: Icons.local_offer_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter offer name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          _fieldLabel('Maximum Discount %'),
          TextFormField(
            controller: _maxDiscountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) {
              setState(() {});
            },
            decoration: _decoration(
              'Example: 25',
              icon: Icons.percent,
            ),
            validator: (value) {
              final number =
                  double.tryParse(value?.trim() ?? '');

              if (number == null ||
                  number <= 0 ||
                  number > 100) {
                return 'Enter a value between 1 and 100';
              }

              return null;
            },
          ),

          const SizedBox(height: 12),

          _couponPreview(),

          const SizedBox(height: 18),

          _fieldLabel('Validity'),
          Row(
            children: [
              _dateButton(
                label: 'Start Date',
                date: _startDate,
                onTap: () => _selectDate(start: true),
              ),
              const SizedBox(width: 10),
              _dateButton(
                label: 'End Date',
                date: _endDate,
                onTap: () => _selectDate(start: false),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _fieldLabel('Minimum Bill'),
          TextFormField(
            controller: _minBillController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: _decoration(
              'Example: 500',
              icon: Icons.currency_rupee,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return null;
              }

              final number = double.tryParse(value.trim());

              if (number == null || number < 0) {
                return 'Enter a valid amount';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          _fieldLabel('Terms & Conditions'),
          TextFormField(
            controller: _termsController,
            maxLines: 3,
            decoration: _decoration(
              'Example: Minimum bill ₹500',
              icon: Icons.description_outlined,
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _creating ? null : _createCampaign,
              icon: _creating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _creating
                    ? 'CREATING...'
                    : 'CREATE 6 COUPONS',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaigns() {
    if (_loadingCampaigns) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (campaigns.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 45,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 10),
            const Text(
              'No coupon offers yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Create your first 6-coupon scratch offer above.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: campaigns
          .map(_campaignCard)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCampaigns,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildForm(),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'My Coupon Offers',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            _buildCampaigns(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}