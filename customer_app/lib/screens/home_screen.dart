// ignore_for_file: use_build_context_synchronously
import '../services/auth_storage.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

import 'package:flutter/material.dart';

import 'notifications_screen.dart';

import 'shop_details_screen.dart';

import 'transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    _HomeContent(),
    TransactionHistoryScreen(),
    _FavoritesPage(),
    _ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  int _unreadNotifications = 0;

  Future<void> _loadUnreadNotifications() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final notifications = await ApiService.getMyNotifications(token: token);

      final count = notifications.where((item) {
        final value = item['is_read'];
        return value == false || value.toString().toLowerCase() == 'false';
      }).length;

      if (!mounted) return;

      setState(() {
        _unreadNotifications = count;
      });
    } catch (_) {
      // Keep home screen usable if notification loading fails.
    }
  }

  late Future<List<Map<String, dynamic>>> businessesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _favoriteBusinessIds = <String>{};
  String _selectedFilterCategory = 'All';
  String _selectedFilterTier = 'All';
  double _minimumDiscount = 0;

  final List<Map<String, dynamic>> categories = const [
    {'name': 'Salon', 'icon': Icons.content_cut},
    {'name': 'Restaurant', 'icon': Icons.restaurant},
    {'name': 'Car Wash', 'icon': Icons.local_car_wash},
    {'name': 'Bike Service', 'icon': Icons.two_wheeler},
    {'name': 'Laundry', 'icon': Icons.local_laundry_service},
    {'name': 'Repair', 'icon': Icons.build},
    {'name': 'Beauty & Spa', 'icon': Icons.spa},
    {'name': 'More', 'icon': Icons.apps},
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadNotifications();
    businessesFuture = ApiService.getPublicBusinesses();
    _loadFavoriteIds();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) return;

      final favorites = await ApiService.getFavorites(token: token);

      if (!mounted) return;

      setState(() {
        _favoriteBusinessIds
          ..clear()
          ..addAll(
            favorites
                .map((item) => item['business_id']?.toString() ?? '')
                .where((id) => id.isNotEmpty),
          );
      });
    } catch (_) {
      // Favorites should not block the home screen.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterShops(List<Map<String, dynamic>> shops) {
    final query = _searchQuery.trim().toLowerCase();

    return shops.where((shop) {
      final name = shop['business_name']?.toString().toLowerCase() ?? '';
      final category = shop['category']?.toString().toLowerCase() ?? '';
      final subcategory = shop['subcategory']?.toString().toLowerCase() ?? '';
      final address = shop['address']?.toString().toLowerCase() ?? '';
      final discountValue =
          double.tryParse(shop['max_discount']?.toString() ?? '') ?? 0;
      final tier = shop['shop_tier']?.toString().toUpperCase() ?? 'SILVER';

      final searchFields = <String>[
        name,
        category,
        subcategory,
        address,
        tier.toLowerCase(),
        discountValue.toString(),
      ];

      final matchesSearch =
          query.isEmpty || searchFields.any((field) => field.contains(query));

      final matchesCategory =
          _selectedFilterCategory == 'All' ||
          category == _selectedFilterCategory.toLowerCase() ||
          subcategory == _selectedFilterCategory.toLowerCase();

      final matchesTier =
          _selectedFilterTier == 'All' ||
          tier == _selectedFilterTier.toUpperCase();

      final matchesDiscount = discountValue >= _minimumDiscount;

      return matchesSearch && matchesCategory && matchesTier && matchesDiscount;
    }).toList();
  }

  Future<void> _openFilters() async {
    var tempCategory = _selectedFilterCategory;
    var tempTier = _selectedFilterTier;
    var tempDiscount = _minimumDiscount;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final categoryOptions = [
              'All',
              ...categories
                  .map((item) => item['name']?.toString() ?? '')
                  .where((name) => name.isNotEmpty && name != 'More'),
            ];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Filter Shops',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: tempCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: categoryOptions
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() {
                            tempCategory = value;
                          });
                        },
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        'Minimum Discount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              min: 0,
                              max: 100,
                              divisions: 20,
                              value: tempDiscount,
                              label: '${tempDiscount.round()}%',
                              onChanged: (value) {
                                setSheetState(() {
                                  tempDiscount = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 55,
                            child: Text(
                              '${tempDiscount.round()}%',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        'Shop Tier',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: tempTier,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All Shops'),
                          ),
                          DropdownMenuItem(value: 'Gold', child: Text('Gold')),
                          DropdownMenuItem(
                            value: 'Silver',
                            child: Text('Silver'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() {
                            tempTier = value;
                          });
                        },
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  tempCategory = 'All';
                                  tempTier = 'All';
                                  tempDiscount = 0;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'CLEAR',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFilterCategory = tempCategory;
                                  _selectedFilterTier = tempTier;
                                  _minimumDiscount = tempDiscount;
                                });
                                Navigator.pop(sheetContext);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'APPLY FILTERS',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconFor(String category) {
    final value = category.toLowerCase();

    if (value.contains('salon') || value.contains('beauty')) {
      return Icons.content_cut;
    }
    if (value.contains('restaurant') || value.contains('cafe')) {
      return Icons.restaurant;
    }
    if (value.contains('car')) {
      return Icons.directions_car;
    }
    if (value.contains('bike')) {
      return Icons.two_wheeler;
    }
    if (value.contains('repair')) {
      return Icons.build;
    }
    if (value.contains('medical')) {
      return Icons.local_pharmacy;
    }
    if (value.contains('grocery')) {
      return Icons.shopping_basket;
    }

    return Icons.storefront;
  }

  String _maxDiscount(dynamic value) {
    if (value == null) return 'OFFER';
    final number = double.tryParse(value.toString());
    if (number == null || number <= 0) return 'OFFER';

    final formatted = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);

    return 'UP TO $formatted% OFF';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          businessesFuture = ApiService.getPublicBusinesses();
        });
        await businessesFuture;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISCOUNT BAZZAR',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Save more. Shop smarter.',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );

                      _loadUnreadNotifications();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: Color(0xFFE0F2F1),
                          child: const Icon(
                            Icons.notifications_none,
                            color: Color(0xFF00796B),
                          ),
                        ),
                        if (_unreadNotifications > 0)
                          Positioned(
                            right: -5,
                            top: -5,
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
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search shops, offers & categories',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        tooltip: 'Filters',
                        onPressed: _openFilters,
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // SEARCH_MODE_MARKER
          if (_searchQuery.trim().isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF00796B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search results for "${_searchQuery.trim()}"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // SEARCH_HOME_SECTIONS_WRAPPED
          if (_searchQuery.trim().isEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00695C), Color(0xFF009688)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover Local Deals',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Gold shops first. Silver shops after them.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.local_offer, color: Colors.white, size: 48),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'View all',
                      style: TextStyle(
                        color: Color(0xFF00796B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final category = categories[index];

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: const Color(0xFFE0F2F1),
                          child: Icon(
                            category['icon'] as IconData,
                            color: const Color(0xFF00796B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: categories.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: .85,
                ),
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: const [
                  Text(
                    'Shops Near You',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.verified, color: Color(0xFF00796B), size: 19),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: businessesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: Colors.black38,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Unable to load shops',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              businessesFuture =
                                  ApiService.getPublicBusinesses();
                            });
                          },
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  );
                }

                final shops = snapshot.data ?? [];
                final filteredShops = _filterShops(shops);

                if (shops.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No approved shops available yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (filteredShops.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 52,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No shops found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No results for "${_searchQuery.trim()}"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredShops.map((shop) {
                    final businessId =
                        shop['business_id']?.toString() ??
                        shop['id']?.toString() ??
                        '';
                    final name =
                        shop['business_name']?.toString() ?? 'Business';
                    final category =
                        shop['category']?.toString() ??
                        shop['subcategory']?.toString() ??
                        'Business';
                    final tier =
                        shop['shop_tier']?.toString().toUpperCase() ?? 'SILVER';
                    final address =
                        shop['address']?.toString() ?? 'Address not provided';
                    final phone =
                        shop['phone']?.toString() ?? 'Phone not provided';

                    return _LiveBusinessCard(
                      businessId: businessId,
                      name: name,
                      category: category,
                      tier: tier,
                      discount: _maxDiscount(shop['max_discount']),
                      address: address,
                      phone: phone,
                      openingTime: shop['opening_time']?.toString() ?? '',
                      closingTime: shop['closing_time']?.toString() ?? '',
                      icon: _iconFor(category),
                      isFavorite: _favoriteBusinessIds.contains(businessId),
                      onFavoriteChanged: (value) {
                        if (!mounted) return;
                        setState(() {
                          if (value) {
                            _favoriteBusinessIds.add(businessId);
                          } else {
                            _favoriteBusinessIds.remove(businessId);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _LiveBusinessCard extends StatelessWidget {
  final String businessId;
  final String name;
  final String category;
  final String tier;
  final String discount;
  final String address;
  final String phone;
  final String openingTime;
  final String closingTime;
  final IconData icon;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;

  const _LiveBusinessCard({
    required this.businessId,
    required this.name,
    required this.category,
    required this.tier,
    required this.discount,
    required this.address,
    required this.phone,
    required this.openingTime,
    required this.closingTime,
    required this.icon,
    required this.isFavorite,
    required this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isGold = tier == 'GOLD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: businessId.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopDetailsScreen(
                          businessId: businessId,
                          shopName: name,
                          category: category,
                          discount: discount,
                          address: address,
                          phone: phone,
                          openingTime: openingTime,
                          closingTime: closingTime,
                          shopTier: tier,
                        ),
                      ),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isGold
                          ? const Color(0xFFFFF3CD)
                          : const Color(0xFFECEFF1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: isGold
                          ? const Color(0xFF8D6E00)
                          : const Color(0xFF455A64),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: isFavorite
                        ? 'Remove from Favorites'
                        : 'Add to Favorites',
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Colors.red.shade500
                          : Colors.grey.shade600,
                      size: 25,
                    ),
                    onPressed: businessId.isEmpty
                        ? null
                        : () async {
                            try {
                              final token = await AuthStorage.getToken();

                              if (token == null || token.isEmpty) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please login to use Favorites.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              if (isFavorite) {
                                await ApiService.removeFavorite(
                                  token: token,
                                  businessId: businessId,
                                );
                              } else {
                                await ApiService.addFavorite(
                                  token: token,
                                  businessId: businessId,
                                );
                              }

                              onFavoriteChanged(!isFavorite);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isFavorite
                                          ? 'Removed from Favorites'
                                          : 'Added to Favorites',
                                    ),
                                    duration: const Duration(milliseconds: 900),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Unable to update Favorite'),
                                  ),
                                );
                              }
                            }
                          },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isGold
                                    ? const Color(0xFFFFF3CD)
                                    : const Color(0xFFECEFF1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tier,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isGold
                                      ? const Color(0xFF8D6E00)
                                      : const Color(0xFF455A64),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.black45,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(
                        discount,
                        style: const TextStyle(
                          color: Color(0xFF00796B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                        color: Color(0xFF00796B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _BusinessCard extends StatelessWidget {
  final String name;
  final String category;
  final String discount;
  final String distance;
  final IconData icon;
  final VoidCallback onTap;

  const _BusinessCard({
    required this.name,
    required this.category,
    required this.discount,
    required this.distance,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF00796B), size: 30),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.black45,
                        ),
                        Text(
                          distance,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    discount,
                    style: const TextStyle(
                      color: Color(0xFF00796B),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: () {}, child: const Text('View')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _CouponsPage extends StatelessWidget {
  const _CouponsPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'My Coupons',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FavoritesPage extends StatefulWidget {
  const _FavoritesPage();

  @override
  State<_FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<_FavoritesPage> {
  late Future<List<Map<String, dynamic>>> favoritesFuture;

  @override
  void initState() {
    super.initState();
    favoritesFuture = _loadFavorites();
  }

  Future<List<Map<String, dynamic>>> _loadFavorites() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      return [];
    }

    return ApiService.getFavorites(token: token);
  }

  Future<void> _refresh() async {
    setState(() {
      favoritesFuture = _loadFavorites();
    });
    await favoritesFuture;
  }

  String _discount(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '');

    if (number == null || number <= 0) {
      return 'OFFER';
    }

    final formatted = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);

    return 'UP TO $formatted% OFF';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FF),
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: const Color(0xFFFFF8FF),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      'Unable to load favorites',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            }

            final favorites = snapshot.data ?? [];

            if (favorites.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No Favorites Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Add shops to your favorites and they will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final shop = favorites[index];

                final businessId = shop['business_id']?.toString() ?? '';
                final name = shop['business_name']?.toString() ?? 'Business';
                final category =
                    shop['category']?.toString() ??
                    shop['subcategory']?.toString() ??
                    'Business';
                final address =
                    shop['address']?.toString() ?? 'Address not provided';
                final tier =
                    shop['shop_tier']?.toString().toUpperCase() ?? 'SILVER';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE0F2F1),
                      child: Icon(
                        Icons.storefront,
                        color: const Color(0xFF00796B),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '$category\n$address',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: SizedBox(
                      width: 115,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.favorite,
                            color: Colors.red.shade400,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _discount(shop['max_discount']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF00796B),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            tier,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: businessId.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShopDetailsScreen(
                                  businessId: businessId,
                                  shopName: name,
                                  category: category,
                                  discount: _discount(shop['max_discount']),
                                  address: address,
                                  phone: shop['phone']?.toString() ?? '',
                                  openingTime:
                                      shop['opening_time']?.toString() ?? '',
                                  closingTime:
                                      shop['closing_time']?.toString() ?? '',
                                  shopTier: tier,
                                ),
                              ),
                            );
                          },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage();

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  String? _name;
  String? _mobile;
  String? _email;
  String? _city;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await AuthStorage.getName();
    final mobile = await AuthStorage.getMobile();
    final email = await AuthStorage.getEmail();
    final city = await AuthStorage.getCity();
    final role = await AuthStorage.getRole();

    if (!mounted) return;

    setState(() {
      _name = name;
      _mobile = mobile;
      _email = email;
      _city = city;
      _role = role;
    });
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _name ?? '');
    final emailController = TextEditingController(text: _email ?? '');
    final cityController = TextEditingController(text: _city ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: cityController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          final city = cityController.text.trim();
                          final token = await AuthStorage.getToken();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your name'),
                              ),
                            );
                            return;
                          }

                          if (token == null || token.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Session expired. Please login again.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);

                          try {
                            final result = await ApiService.updateProfile(
                              token: token,
                              name: name,
                              email: email,
                              city: city,
                            );

                            if (result['success'] == true) {
                              await AuthStorage.updateProfile(
                                name: name,
                                email: email,
                                city: city,
                              );

                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext, true);
                              }
                            } else {
                              if (dialogContext.mounted) {
                                setDialogState(() => saving = false);
                              }

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message']?.toString() ??
                                        'Unable to update profile',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => saving = false);
                            }

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Unable to update profile. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await _loadProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  Future<void> _logout() async {
    await AuthStorage.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (_name == null || _name!.trim().isEmpty)
        ? 'Customer'
        : _name!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.notifications_outlined),
                ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('View your latest notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CircleAvatar(
                  radius: 42,
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _role ?? 'CUSTOMER',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('EDIT PROFILE'),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Mobile Number'),
                        subtitle: Text(
                          _mobile == null || _mobile!.isEmpty
                              ? 'Not available'
                              : '+91 $_mobile',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(
                          _email == null || _email!.isEmpty
                              ? 'Not added'
                              : _email!,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.location_city_outlined),
                        title: const Text('City'),
                        subtitle: Text(
                          _city == null || _city!.isEmpty
                              ? 'Not added'
                              : _city!,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('LOGOUT'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
