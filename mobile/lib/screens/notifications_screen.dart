import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/notifications');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['data'] != null) {
          setState(() => _notifications = List<dynamic>.from(data['data']));
        }
      }
    } catch (e) {
      debugPrint('Notifications load error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(dynamic notification) async {
    try {
      final id = notification['id'];
      final response = await ApiService.patch('/notifications/$id/read');
      if (response.statusCode == 200) {
        setState(() {
          notification['is_read'] = 1;
        });
      }
    } catch (e) {
      debugPrint('Mark notification read error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('ไม่มีการแจ้งเตือน'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final read = notification['is_read'] == 1 || notification['is_read'] == true;
                      return Card(
                        color: read ? Colors.grey.shade100 : Colors.white,
                        child: ListTile(
                          title: Text(notification['message'] ?? 'ไม่ระบุข้อความ'),
                          subtitle: Text(notification['created_at']?.toString() ?? ''),
                          trailing: read
                              ? const Icon(Icons.done, color: Colors.green)
                              : TextButton(
                                  onPressed: () => _markAsRead(notification),
                                  child: const Text('ทำเครื่องหมายแล้ว'),
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
