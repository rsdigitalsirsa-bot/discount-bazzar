import 'package:flutter/material.dart';

import 'shop_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    _HomeContent(),
    _CouponsPage(),
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
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'My Coupons',
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

class _HomeContent extends StatelessWidget {
  const _HomeContent();

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
  Widget build(BuildContext context) {
    return CustomScrollView(
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
                CircleAvatar(
                  radius: 21,
                  backgroundColor: Color(0xFFE0F2F1),
                  child: Icon(
                    Icons.notifications_none,
                    color: Color(0xFF00796B),
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
              decoration: InputDecoration(
                hintText: 'Search shops, offers & categories',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.tune),
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
                          'Find nearby businesses and claim exclusive discounts.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Nearby Deals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'See all',
                  style: TextStyle(
                    color: Color(0xFF00796B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildListDelegate([
            _BusinessCard(
              name: 'Premium Family Salon',
              category: 'Salon & Beauty',
              discount: '30% OFF',
              distance: '1.2 km',
              icon: Icons.content_cut,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ShopDetailsScreen(
                    shopName: 'Premium Family Salon',
                    category: 'Salon & Beauty',
                    discount: '30% OFF',
                  ),
                ),
              ),
            ),
            _BusinessCard(
              name: 'Food Junction',
              category: 'Restaurant & Cafe',
              discount: '20% OFF',
              distance: '2.4 km',
              icon: Icons.restaurant,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ShopDetailsScreen(
                    shopName: 'Food Junction',
                    category: 'Restaurant & Cafe',
                    discount: '20% OFF',
                  ),
                ),
              ),
            ),
            _BusinessCard(
              name: 'Quick Auto Care',
              category: 'Car & Bike Service',
              discount: '25% OFF',
              distance: '3.1 km',
              icon: Icons.car_repair,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ShopDetailsScreen(
                    shopName: 'Quick Auto Care',
                    category: 'Car & Bike Service',
                    discount: '25% OFF',
                  ),
                ),
              ),
            ),
          ]),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

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

class _FavoritesPage extends StatelessWidget {
  const _FavoritesPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Favorites',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
