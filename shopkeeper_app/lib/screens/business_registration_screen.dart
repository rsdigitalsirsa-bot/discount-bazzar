import 'package:flutter/material.dart';

import 'business_details_screen.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  State<BusinessRegistrationScreen> createState() =>
      _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState
    extends State<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  String? _category;
  String? _subcategory;

  final List<String> _categories = [
    'Cafe',
    'Restaurant',
    'Salon',
    'Repair',
    'Car Service',
    'Clothing',
    'Grocery',
    'Electronics',
    'Medical',
    'Hotel',
    'Other',
  ];

  final List<String> _subcategories = [
    'General',
    'Premium',
    'Home Service',
    'Retail',
    'Wholesale',
    'Other',
  ];

  @override
  void dispose() {
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessDetailsScreen(
          ownerName: _ownerNameController.text.trim(),
          businessName: _businessNameController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          category: _category ?? '',
          subcategory: _subcategory ?? '',
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          pincode: _pincodeController.text.trim(),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Registration'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Business Registration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your basic business information.',
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _ownerNameController,
              decoration: _decoration(
                label: 'Owner Name',
                icon: Icons.person_outline,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Owner name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _businessNameController,
              decoration: _decoration(
                label: 'Business Name',
                icon: Icons.storefront_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: _decoration(
                label: 'Mobile',
                icon: Icons.phone_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Mobile number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoration(
                label: 'Email',
                icon: Icons.email_outlined,
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _decoration(
                label: 'Business Category',
                icon: Icons.category_outlined,
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _category = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _subcategory,
              decoration: _decoration(
                label: 'Subcategory',
                icon: Icons.account_tree_outlined,
              ),
              items: _subcategories.map((subcategory) {
                return DropdownMenuItem(
                  value: subcategory,
                  child: Text(subcategory),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _subcategory = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select subcategory';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: _decoration(
                label: 'Address',
                icon: Icons.location_on_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Address is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _cityController,
              decoration: _decoration(
                label: 'City',
                icon: Icons.location_city_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'City is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: _decoration(
                label: 'Pincode',
                icon: Icons.pin_drop_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Pincode is required';
                }

                if (value.trim().length != 6) {
                  return 'Enter valid 6 digit pincode';
                }

                return null;
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _continue,
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}