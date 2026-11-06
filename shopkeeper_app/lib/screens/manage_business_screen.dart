import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class ManageBusinessScreen extends StatefulWidget {
  const ManageBusinessScreen({super.key});

  @override
  State<ManageBusinessScreen> createState() =>
      _ManageBusinessScreenState();
}

class _ManageBusinessScreenState extends State<ManageBusinessScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;

  String? _error;
  Map<String, dynamic>? _business;

  final _formKey = GlobalKey<FormState>();

  final _ownerNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _category;
  String? _subcategory;
  String? _weeklyHoliday;

  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

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

  final List<String> _holidays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'No Weekly Holiday',
  ];

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _error = 'Session expired. Please login again.';
        });
        return;
      }

      final result = await ApiService.getMyBusiness(
        token: token,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];

        if (data is Map) {
          final business =
              Map<String, dynamic>.from(data);

          _business = business;
          _fillControllers(business);
        }

        setState(() {
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = result['message']?.toString() ??
              'Unable to load business profile.';
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load business profile.';
      });
    }
  }

  void _fillControllers(Map<String, dynamic> data) {
    _ownerNameController.text =
        data['ownerName']?.toString() ?? '';

    _businessNameController.text =
        data['businessName']?.toString() ?? '';

    _phoneController.text =
        data['phone']?.toString() ??
        data['businessPhone']?.toString() ??
        '';

    _emailController.text =
        data['email']?.toString() ??
        data['shopkeeperEmail']?.toString() ??
        '';

    _addressController.text =
        data['address']?.toString() ?? '';

    _cityController.text =
        data['city']?.toString() ?? '';

    _pincodeController.text =
        data['pincode']?.toString() ?? '';

    _descriptionController.text =
        data['description']?.toString() ?? '';

    final category =
        data['category']?.toString();

    final subcategory =
        data['subcategory']?.toString();

    final holiday =
        data['weeklyHoliday']?.toString();

    _category =
        _categories.contains(category) ? category : null;

    _subcategory =
        _subcategories.contains(subcategory)
            ? subcategory
            : null;

    _weeklyHoliday =
        _holidays.contains(holiday) ? holiday : null;

    _openingTime =
        _parseTime(data['openingTime']?.toString());

    _closingTime =
        _parseTime(data['closingTime']?.toString());
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());

    if (match == null) {
      return null;
    }

    int hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final period = match.group(3)!.toUpperCase();

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    if (hour > 23 || minute > 59) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return '';
    }

    final hour =
        time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  Future<void> _selectOpeningTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _openingTime ??
          const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _openingTime = picked;
      });
    }
  }

  Future<void> _selectClosingTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _closingTime ??
          const TimeOfDay(hour: 21, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _closingTime = picked;
      });
    }
  }

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_openingTime == null) {
      _showMessage('Please select opening time');
      return;
    }

    if (_closingTime == null) {
      _showMessage('Please select closing time');
      return;
    }

    if (_weeklyHoliday == null) {
      _showMessage('Please select weekly holiday');
      return;
    }

    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      _showMessage('Session expired. Please login again.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final result = await ApiService.updateMyBusiness(
        token: token,
        data: {
          'ownerName':
              _ownerNameController.text.trim(),
          'businessName':
              _businessNameController.text.trim(),
          'businessPhone':
              _phoneController.text.trim(),
          'email':
              _emailController.text.trim(),
          'category':
              _category,
          'subcategory':
              _subcategory,
          'address':
              _addressController.text.trim(),
          'city':
              _cityController.text.trim(),
          'pincode':
              _pincodeController.text.trim(),
          'description':
              _descriptionController.text.trim(),
          'openingTime':
              _formatTime(_openingTime),
          'closingTime':
              _formatTime(_closingTime),
          'weeklyHoliday':
              _weeklyHoliday,
          'images':
              _business?['images'] ?? [],
          'logoUrl':
              _business?['logoUrl'],
          'whatsapp':
              _business?['whatsapp'],
          'terms':
              _business?['terms'],
        },
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _editing = false;
        });

        _showMessage(
          'Business updated successfully. Sent for approval.',
        );

        await _loadBusiness();
      } else {
        _showMessage(
          result['message']?.toString() ??
              'Failed to update business.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Unable to connect to server. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _value(String key) {
    final value = _business?[key];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'Not provided';
    }

    return value.toString();
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled && !_saving,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: _decoration(
          label: label,
          icon: icon,
        ),
        validator: (value) {
          if (label == 'Email') {
            return null;
          }

          if (value == null ||
              value.trim().isEmpty) {
            return '$label is required';
          }

          return null;
        },
      ),
    );
  }

  Widget _editForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Edit Business Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Changes will be sent to admin for approval.',
          ),
          const SizedBox(height: 24),

          _field(
            controller: _ownerNameController,
            label: 'Owner Name',
            icon: Icons.person_outline,
          ),

          _field(
            controller: _businessNameController,
            label: 'Business Name',
            icon: Icons.storefront_outlined,
          ),

          _field(
            controller: _phoneController,
            label: 'Phone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          _field(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: _decoration(
              label: 'Business Category',
              icon: Icons.category_outlined,
            ),
            items: _categories.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: _saving
                ? null
                : (value) {
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
            items: _subcategories.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: _saving
                ? null
                : (value) {
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

          _field(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            maxLines: 3,
          ),

          _field(
            controller: _cityController,
            label: 'City',
            icon: Icons.location_city_outlined,
          ),

          _field(
            controller: _pincodeController,
            label: 'Pincode',
            icon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
          ),

          _field(
            controller: _descriptionController,
            label: 'Business Description',
            icon: Icons.description_outlined,
            maxLines: 5,
          ),

          InkWell(
            onTap: _saving ? null : _selectOpeningTime,
            child: InputDecorator(
              decoration: _decoration(
                label: 'Opening Time',
                icon: Icons.access_time,
              ),
              child: Text(
                _openingTime == null
                    ? 'Select time'
                    : _formatTime(_openingTime),
              ),
            ),
          ),

          const SizedBox(height: 16),

          InkWell(
            onTap: _saving ? null : _selectClosingTime,
            child: InputDecorator(
              decoration: _decoration(
                label: 'Closing Time',
                icon: Icons.access_time_filled,
              ),
              child: Text(
                _closingTime == null
                    ? 'Select time'
                    : _formatTime(_closingTime),
              ),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _weeklyHoliday,
            decoration: _decoration(
              label: 'Weekly Holiday',
              icon: Icons.event_busy_outlined,
            ),
            items: _holidays.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: _saving
                ? null
                : (value) {
                    setState(() {
                      _weeklyHoliday = value;
                    });
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select weekly holiday';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveBusiness,
              icon: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _saving
                    ? 'SAVING...'
                    : 'SAVE CHANGES',
              ),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: _saving
                ? null
                : () {
                    setState(() {
                      _editing = false;
                    });
                  },
            child: const Text('CANCEL'),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value),
        ),
      ),
    );
  }

  Widget _viewMode() {
    final status =
        _value('verificationStatus').toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _value('businessName'),
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 8),

        Chip(
          avatar: Icon(
            status == 'VERIFIED'
                ? Icons.verified_outlined
                : Icons.hourglass_top_outlined,
            size: 18,
          ),
          label: Text(status),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: () {
              setState(() {
                _editing = true;
              });
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('EDIT BUSINESS'),
          ),
        ),

        const SizedBox(height: 20),

        _infoCard(
          icon: Icons.person_outline,
          title: 'Owner Name',
          value: _value('ownerName'),
        ),

        _infoCard(
          icon: Icons.category_outlined,
          title: 'Category',
          value: _value('category'),
        ),

        _infoCard(
          icon: Icons.account_tree_outlined,
          title: 'Subcategory',
          value: _value('subcategory'),
        ),

        _infoCard(
          icon: Icons.location_on_outlined,
          title: 'Address',
          value: _value('address'),
        ),

        _infoCard(
          icon: Icons.location_city_outlined,
          title: 'City',
          value: _value('city'),
        ),

        _infoCard(
          icon: Icons.pin_drop_outlined,
          title: 'Pincode',
          value: _value('pincode'),
        ),

        _infoCard(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: _value('phone'),
        ),

        _infoCard(
          icon: Icons.email_outlined,
          title: 'Email',
          value: _value('email'),
        ),

        _infoCard(
          icon: Icons.description_outlined,
          title: 'Business Description',
          value: _value('description'),
        ),

        _infoCard(
          icon: Icons.access_time,
          title: 'Opening Time',
          value: _value('openingTime'),
        ),

        _infoCard(
          icon: Icons.access_time_filled,
          title: 'Closing Time',
          value: _value('closingTime'),
        ),

        _infoCard(
          icon: Icons.event_busy_outlined,
          title: 'Weekly Holiday',
          value: _value('weeklyHoliday'),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Customer Visibility'),
            subtitle: Text(
              _business?['isPublic'] == true
                  ? 'Visible to customers'
                  : 'Not visible to customers',
            ),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing
              ? 'Edit Business'
              : 'Manage My Business',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                (_loading || _saving) ? null : _loadBusiness,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loadBusiness,
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                )
              : _business == null
                  ? const Center(
                      child: Text(
                        'Business profile not found.',
                      ),
                    )
                  : _editing
                      ? _editForm()
                      : _viewMode(),
    );
  }
}
