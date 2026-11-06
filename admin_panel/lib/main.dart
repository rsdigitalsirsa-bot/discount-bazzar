import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const DiscountBazzarAdmin());
}

class DiscountBazzarAdmin extends StatelessWidget {
  const DiscountBazzarAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Discount Bazzar Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const AdminAuthGate(),
    );
  }
}


// ============================================================
// ADMIN AUTHENTICATION
// ============================================================

class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  final mobileController = TextEditingController();
  final otpController = TextEditingController();

  bool loading = false;
  bool otpRequested = false;
  String? error;
  String? developmentOtp;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_token');
    final role = prefs.getString('admin_role');

    if (!mounted) return;

    if (token != null && token.isNotEmpty && role == 'ADMIN') {
      AdminApi.setToken(token);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
      );
    }
  }

  Future<void> _requestOtp() async {
    final mobile = mobileController.text.trim();
    if (!RegExp(r'^[0-9]{10}$').hasMatch(mobile)) {
      setState(() => error = 'Enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
      developmentOtp = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AdminApi.baseUrl}/api/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Could not request OTP.');
      }

      setState(() {
        otpRequested = true;
        developmentOtp = data['developmentOtp']?.toString();
      });
    } catch (e) {
      setState(() => error = 'OTP request failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final mobile = mobileController.text.trim();
    final otp = otpController.text.trim();

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      setState(() => error = 'Enter the 6-digit OTP.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AdminApi.baseUrl}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'otp': otp,
          'role': 'ADMIN',
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = data['user'];

      if (response.statusCode != 200 ||
          data['success'] != true ||
          user is! Map ||
          user['role'] != 'ADMIN' ||
          data['token'] is! String) {
        throw Exception(data['message'] ?? 'Admin verification failed.');
      }

      final token = data['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_token', token);
      await prefs.setString('admin_role', 'ADMIN');
      AdminApi.setToken(token);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
      );
    } catch (e) {
      setState(() => error = 'Login failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    mobileController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'DISCOUNT BAZAAR ADMIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      enabled: !otpRequested && !loading,
                      decoration: const InputDecoration(
                        labelText: 'Admin mobile number',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    if (otpRequested) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit OTP',
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                      if (developmentOtp != null) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          'Development OTP: $developmentOtp',
                        ),
                      ],
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading
                            ? null
                            : otpRequested
                                ? _verifyOtp
                                : _requestOtp,
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(otpRequested ? 'VERIFY & LOGIN' : 'REQUEST OTP'),
                      ),
                    ),
                    if (otpRequested)
                      TextButton(
                        onPressed: loading
                            ? null
                            : () => setState(() {
                                  otpRequested = false;
                                  otpController.clear();
                                  error = null;
                                }),
                        child: const Text('Change mobile number'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// API SERVICE
// ============================================================

class AdminApi {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
    await prefs.remove('admin_role');
  }

  static const String baseUrl =
      'https://cuddly-engine-r76pv47xgv5jhp5v-4000.app.github.dev';

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/dashboard'),
      headers: authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard');
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  static Future<List<dynamic>> getPendingBusinesses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/pending-businesses'),
      headers: authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load pending businesses');
    }

    final data = jsonDecode(response.body);

    return List<dynamic>.from(data['data'] ?? []);
  }

  static Future<List<dynamic>> getApprovedBusinesses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/approved-businesses'),
      headers: authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load approved businesses');
    }

    final data = jsonDecode(response.body);

    return List<dynamic>.from(data['data'] ?? []);
  }

  static Future<void> approveBusiness(String id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/admin/businesses/$id/approve'),
      headers: authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to approve business: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<void> rejectBusiness(String id) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/admin/businesses/$id/reject'),
      headers: authHeaders,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to reject business: '
        '${response.statusCode} ${response.body}',
      );
    }
  }
}

// ============================================================
// ADMIN HOME
// ============================================================

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int selectedIndex = 0;

  final List<String> menuItems = [
    'Dashboard',
    'Pending Businesses',
    'Approved Businesses',
    'Customers',
    'Shopkeepers',
    'Coupons',
    'Transactions',
    'Subscriptions',
    'Notifications',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DISCOUNT BAZAAR ADMIN',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AdminApi.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AdminAuthGate()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: const Column(
                  children: [
                    Icon(
                      Icons.storefront,
                      size: 55,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'DISCOUNT BAZAAR',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('ADMIN PANEL'),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(_menuIcon(index)),
                      title: Text(menuItems[index]),
                      selected: selectedIndex == index,
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildPage(),
    );
  }

  IconData _menuIcon(int index) {
    const icons = [
      Icons.dashboard,
      Icons.pending_actions,
      Icons.verified,
      Icons.people,
      Icons.store,
      Icons.local_offer,
      Icons.receipt_long,
      Icons.payment,
      Icons.notifications,
      Icons.settings,
    ];

    return icons[index];
  }

  Widget _buildPage() {
    switch (selectedIndex) {
      case 0:
        return const DashboardPage();

      case 1:
        return const PendingBusinessesPage();

      case 2:
        return const ApprovedBusinessesPage();

      default:
        return Center(
          child: Text(
            menuItems[selectedIndex],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  String? error;

  int pendingBusinesses = 0;
  int approvedBusinesses = 0;
  int rejectedBusinesses = 0;
  int customers = 0;
  int shopkeepers = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final result = await AdminApi.getDashboard();
      final data = result['data'] ?? {};

      if (!mounted) return;

      setState(() {
        pendingBusinesses =
            int.tryParse('${data['pendingBusinesses']}') ?? 0;

        approvedBusinesses =
            int.tryParse('${data['approvedBusinesses']}') ?? 0;

        rejectedBusinesses =
            int.tryParse('${data['rejectedBusinesses']}') ?? 0;

        customers =
            int.tryParse('${data['customers']}') ?? 0;

        shopkeepers =
            int.tryParse('${data['shopkeepers']}') ?? 0;

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(error!),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loadDashboard,
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Discount Bazzar platform overview',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                StatCard(
                  title: 'Pending Businesses',
                  value: '$pendingBusinesses',
                  icon: Icons.pending_actions,
                ),
                StatCard(
                  title: 'Approved Businesses',
                  value: '$approvedBusinesses',
                  icon: Icons.verified,
                ),
                StatCard(
                  title: 'Customers',
                  value: '$customers',
                  icon: Icons.people,
                ),
                StatCard(
                  title: 'Shopkeepers',
                  value: '$shopkeepers',
                  icon: Icons.store,
                ),
                StatCard(
                  title: 'Rejected Businesses',
                  value: '$rejectedBusinesses',
                  icon: Icons.block,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(title),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// APPROVED BUSINESSES
// ============================================================

class ApprovedBusinessesPage extends StatefulWidget {
  const ApprovedBusinessesPage({super.key});

  @override
  State<ApprovedBusinessesPage> createState() =>
      _ApprovedBusinessesPageState();
}

class _ApprovedBusinessesPageState
    extends State<ApprovedBusinessesPage> {
  bool loading = true;
  String? error;
  List<dynamic> businesses = [];

  @override
  void initState() {
    super.initState();
    loadBusinesses();
  }

  Future<void> loadBusinesses() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result =
          await AdminApi.getApprovedBusinesses();

      if (!mounted) return;

      setState(() {
        businesses = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load approved businesses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(error!),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loadBusinesses,
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadBusinesses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approved Businesses',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Businesses verified and visible to customers',
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: loadBusinesses,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (businesses.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 60,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No approved businesses found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...businesses.map(
                (business) {
                  final data =
                      Map<String, dynamic>.from(business);

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 16,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                child: Icon(
                                  Icons.storefront,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  data['business_name']
                                          ?.toString() ??
                                      'Business',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons.verified,
                                  size: 18,
                                ),
                                label: const Text(
                                  'VERIFIED',
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 30),
                          Wrap(
                            spacing: 30,
                            runSpacing: 15,
                            children: [
                              _info(
                                Icons.person,
                                'Owner',
                                data['owner_name'],
                              ),
                              _info(
                                Icons.phone,
                                'Phone',
                                data['phone'] ??
                                    data['business_phone'],
                              ),
                              _info(
                                Icons.location_on,
                                'Address',
                                data['address'],
                              ),
                              _info(
                                Icons.location_city,
                                'Pincode',
                                data['pincode'],
                              ),
                              _info(
                                Icons.email,
                                'Email',
                                data['email'] ??
                                    data['shopkeeper_email'],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _info(
    IconData icon,
    String label,
    dynamic value,
  ) {
    return SizedBox(
      width: 260,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value?.toString().isNotEmpty == true
                      ? value.toString()
                      : 'Not provided',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PENDING BUSINESSES
// ============================================================

class PendingBusinessesPage extends StatefulWidget {
  const PendingBusinessesPage({super.key});

  @override
  State<PendingBusinessesPage> createState() =>
      _PendingBusinessesPageState();
}

class _PendingBusinessesPageState
    extends State<PendingBusinessesPage> {
  bool loading = true;
  String? error;
  List<dynamic> businesses = [];

  @override
  void initState() {
    super.initState();
    loadBusinesses();
  }

  Future<void> loadBusinesses() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result =
          await AdminApi.getPendingBusinesses();

      if (!mounted) return;

      setState(() {
        businesses = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> approveBusiness(
    Map<String, dynamic> business,
  ) async {
    final id = business['business_id'].toString();

    try {
      await AdminApi.approveBusiness(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Business approved successfully',
          ),
        ),
      );

      await loadBusinesses();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Approval failed: $e',
          ),
        ),
      );
    }
  }

  Future<void> rejectBusiness(
    Map<String, dynamic> business,
  ) async {
    final id = business['business_id'].toString();

    try {
      await AdminApi.rejectBusiness(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Business rejected successfully',
          ),
        ),
      );

      await loadBusinesses();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rejection failed: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load businesses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(error!),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loadBusinesses,
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadBusinesses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Businesses',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Businesses waiting for admin verification',
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: loadBusinesses,
                  icon: const Icon(Icons.refresh),
                  label: const Text('REFRESH'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (businesses.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 60,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'No pending businesses',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ...businesses.map(
              (item) {
                final business =
                    Map<String, dynamic>.from(item);

                return BusinessCard(
                  business: business,
                  onApprove: () =>
                      approveBusiness(business),
                  onReject: () =>
                      rejectBusiness(business),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BUSINESS CARD
// ============================================================

class BusinessCard extends StatelessWidget {
  final Map<String, dynamic> business;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const BusinessCard({
    super.key,
    required this.business,
    required this.onApprove,
    required this.onReject,
  });

  String value(String key) {
    final data = business[key];

    if (data == null ||
        data.toString().trim().isEmpty) {
      return '-';
    }

    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(
                    Icons.store,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value('business_name'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 35),
            Wrap(
              spacing: 40,
              runSpacing: 20,
              children: [
                InfoItem(
                  title: 'Owner',
                  value: value('owner_name'),
                  icon: Icons.person,
                ),
                InfoItem(
                  title: 'Mobile',
                  value: value('user_mobile'),
                  icon: Icons.phone,
                ),
                InfoItem(
                  title: 'Category',
                  value: value('category_name'),
                  icon: Icons.category,
                ),
                InfoItem(
                  title: 'City',
                  value: value('city_name'),
                  icon: Icons.location_city,
                ),
                InfoItem(
                  title: 'Pincode',
                  value: value('pincode'),
                  icon: Icons.pin_drop,
                ),
                InfoItem(
                  title: 'Email',
                  value: value('email'),
                  icon: Icons.email,
                ),
              ],
            ),
            const SizedBox(height: 20),
            InfoItem(
              title: 'Address',
              value: value('address'),
              icon: Icons.location_on,
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                  label: const Text('REJECT'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check),
                  label: const Text('APPROVE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// INFO ITEM
// ============================================================

class InfoItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const InfoItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}