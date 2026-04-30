import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class UserRequestsScreen extends StatefulWidget {
  const UserRequestsScreen({super.key});

  @override
  State<UserRequestsScreen> createState() => _UserRequestsScreenState();
}

class _UserRequestsScreenState extends State<UserRequestsScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/adoptions/my');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _requests = List<dynamic>.from(data['adoptions'] ?? []));
      }
    } catch (e) {
      debugPrint('Load user requests error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('คำขอรับเลี้ยงของฉัน'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('ยังไม่มีคำขอรับเลี้ยง')), 
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(request['dogName'] ?? 'ไม่พบชื่อสุนัข'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('สถานะ: ${request['status'] ?? '-'}'),
                              if (request['verification_status'] != null)
                                Text('ผลตรวจสอบ: ${request['verification_status']}'),
                              if (request['rejection_reason'] != null)
                                Text('เหตุผล: ${request['rejection_reason']}'),
                            ],
                          ),
                          trailing: Text(request['created_at']?.toString() ?? ''),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
