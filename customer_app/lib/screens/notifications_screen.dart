import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login again');
    }

    return ApiService.getMyNotifications(token: token);
  }

  Future<void> _markRead(String id) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) return;

    await ApiService.markNotificationRead(
      token: token,
      notificationId: id,
    );

    if (!mounted) return;

    setState(() {
      _future = _load();
    });
  }

  Future<void> _markAllRead() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) return;

    await ApiService.markAllNotificationsRead(token: token);

    if (!mounted) return;

    setState(() {
      _future = _load();
    });
  }

  String _text(dynamic value) {
    return value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Text('Unable to load notifications'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _future = _load();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 60,
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
              setState(() {
                _future = _load();
              });
              await _future;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];

                final id = _text(n['id']);
                final title = _text(n['title']);
                final message = _text(n['message']);
                final type = _text(n['type']);
                final isRead = n['is_read'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: !isRead && id.isNotEmpty
                        ? () => _markRead(id)
                        : null,
                    leading: CircleAvatar(
                      child: Icon(
                        type == 'TRANSACTION'
                            ? Icons.receipt_long
                            : Icons.notifications,
                      ),
                    ),
                    title: Text(
                      title.isEmpty ? 'Notification' : title,
                      style: TextStyle(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(message),
                    ),
                    trailing: isRead
                        ? null
                        : const Icon(
                            Icons.circle,
                            size: 10,
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
