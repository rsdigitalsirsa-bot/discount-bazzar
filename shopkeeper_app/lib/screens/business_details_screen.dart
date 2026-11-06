import '../services/api_service.dart';
import 'dashboard_screen.dart';
import '../services/auth_storage.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class BusinessDetailsScreen extends StatefulWidget {
  final String ownerName;
  final String businessName;
  final String mobile;
  final String email;
  final String category;
  final String subcategory;
  final String address;
  final String city;
  final String pincode;

  const BusinessDetailsScreen({
    super.key,
    required this.ownerName,
    required this.businessName,
    required this.mobile,
    required this.email,
    required this.category,
    required this.subcategory,
    required this.address,
    required this.city,
    required this.pincode,
  });

  @override
  State<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();

  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  String? _weeklyHoliday;

  bool _isSubmitting = false;

  static const String _baseUrl =
      'https://cuddly-engine-r76pv47xgv5jhp5v-4000.app.github.dev';

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
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return 'Select time';
    }

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  Future<void> _selectOpeningTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _openingTime ?? const TimeOfDay(hour: 9, minute: 0),
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
      initialTime: _closingTime ?? const TimeOfDay(hour: 21, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _closingTime = picked;
      });
    }
  }

  Future<String?> _getToken() async {
  return AuthStorage.getToken();
}

  Future<void> _submitForApproval() async {
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _showMessage('Session expired. Please login again.');
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/businesses/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ownerName': widget.ownerName,
          'businessName': widget.businessName,
          'mobile': widget.mobile,
          'email': widget.email,
          'category': widget.category,
          'subcategory': widget.subcategory,
          'address': widget.address,
          'city': widget.city,
          'pincode': widget.pincode,
          'businessPhone': widget.mobile,
          'description': _descriptionController.text.trim(),
          'openingTime': _formatTime(_openingTime),
          'closingTime': _formatTime(_closingTime),
          'weeklyHoliday': _weeklyHoliday,
          'images': [],
        }),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const VerificationPendingScreen(),
          ),
        );
        return;
      }

      String message = 'Failed to submit business';

      try {
        final data = jsonDecode(response.body);

        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      } catch (_) {}

      _showMessage(message);
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Unable to connect to server. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
        title: const Text('Business Details'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Business Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your business information to submit it for approval.',
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: _decoration(
                label: 'Business Description',
                icon: Icons.description_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _selectOpeningTime,
              child: InputDecorator(
                decoration: _decoration(
                  label: 'Opening Time',
                  icon: Icons.access_time,
                ),
                child: Text(_formatTime(_openingTime)),
              ),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _selectClosingTime,
              child: InputDecorator(
                decoration: _decoration(
                  label: 'Closing Time',
                  icon: Icons.access_time_filled,
                ),
                child: Text(_formatTime(_closingTime)),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _weeklyHoliday,
              decoration: _decoration(
                label: 'Weekly Holiday',
                icon: Icons.event_busy_outlined,
              ),
              items: _holidays.map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (value) {
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
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Business Logo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Logo upload will be connected next.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Shop Photos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Shop photo upload will be connected next.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitForApproval,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(),
                      )
                    : const Text(
                        'SUBMIT FOR APPROVAL',
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

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState
    extends State<VerificationPendingScreen> {
  bool _loading = true;
  String _status = 'PENDING';
  String? _businessName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
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

      final result = await ApiService.getMyBusinessStatus(
        token: token,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;

        final status =
            (data?['verificationStatus'] ?? 'PENDING')
                .toString()
                .toUpperCase();

        if (status == 'VERIFIED') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
            ),
            (route) => false,
          );
          return;
        }

        setState(() {
          _loading = false;
          _status = status;
          _businessName = data?['businessName']?.toString();
        });
      } else {
        setState(() {
          _loading = false;
          _error = result['message']?.toString() ??
              'Unable to check verification status.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to check verification status.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _status == 'REJECTED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Status'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isRejected
                    ? Icons.cancel_outlined
                    : Icons.hourglass_top_rounded,
                size: 72,
              ),
              const SizedBox(height: 24),
              Text(
                isRejected
                    ? 'Verification Rejected'
                    : 'Verification Pending',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_businessName != null) ...[
                const SizedBox(height: 8),
                Text(
                  _businessName!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                isRejected
                    ? 'Your business verification was rejected. Please contact DISCOUNT BAZAAR support.'
                    : 'Your business has been submitted and is being reviewed by DISCOUNT BAZAAR.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: _checkStatus,
                      child: const Text('CHECK STATUS'),
                    ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text('BACK TO DASHBOARD'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

