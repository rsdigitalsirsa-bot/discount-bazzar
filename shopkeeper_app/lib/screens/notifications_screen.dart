
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      return [];
    }

    return ApiService.getMyNotifications(token: token);
  }

  Future<void> _markAllRead() async {
    if (_markingRead) return;

    setState(() {
      _markingRead = true;
    });

    try {
      final token = await AuthStorage.getToken();

      if (token != null && token.isNotEmpty) {
        await ApiService.markAllNotificationsRead(token: token);
      }

      if (!mounted) return;

      setState(() {
        _load();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to mark notifications as read'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _markingRead = false;
        });
      }
    }
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'TRANSACTION':
        return Icons.receipt_long_outlined;
      case 'COUPON':
        return Icons.local_offer_outlined;
      case 'BUSINESS':
        return Icons.storefront_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markingRead ? null : _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load notifications'),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text('No notifications yet'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_load);
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = notifications[index];

                final title =
                    item['title']?.toString() ?? 'Notification';
                final message =
                    item['message']?.toString() ?? '';
                final type =
                    item['type']?.toString();
                final isRead = item['is_read'] == true;

                return Card(
                  elevation: isRead ? 0 : 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(_iconFor(type)),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(message),
                    ),
                    trailing: isRead
                        ? null
                        : const Icon(
                            Icons.circle,
                            size: 9,
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
