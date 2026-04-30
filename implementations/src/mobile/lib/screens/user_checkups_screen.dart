import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class UserCheckupsScreen extends StatefulWidget {
  const UserCheckupsScreen({super.key});

  @override
  State<UserCheckupsScreen> createState() => _UserCheckupsScreenState();
}

class _UserCheckupsScreenState extends State<UserCheckupsScreen> {
  bool _isLoading = true;
  List<dynamic> _checkups = [];

  @override
  void initState() {
    super.initState();
    _loadCheckups();
  }

  Future<void> _loadCheckups() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/checkups');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _checkups = List<dynamic>.from(data['checkups'] ?? []));
      }
    } catch (e) {
      debugPrint('Load checkups error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดตามรายเดือน'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCheckups,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _checkups.isEmpty
                ? const ListView(
                    children: [
                      SizedBox(height: 120),
                      Center(child: Text('ยังไม่มีข้อมูลติดตาม')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _checkups.length,
                    itemBuilder: (context, index) {
                      final item = _checkups[index];
                      final followups = List<dynamic>.from(item['followups'] ?? []);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(item['dog_name'] ?? 'ไม่พบชื่อสุนัข'),
                          subtitle: Text('สถานะ: ${item['delivery_status'] ?? '-'}'),
                          children: followups.isEmpty
                              ? [const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('ยังไม่มีบันทึกการติดตาม'),
                                )]
                              : followups.map((followup) {
                                  return ListTile(
                                    title: Text('เดือนที่ ${followup['month'] ?? '-'}'),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(followup['note'] ?? '-'),
                                        if (followup['date'] != null)
                                          Text('วันที่: ${followup['date']}'),
                                      ],
                                    ),
                                  );
                                }).toList(),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
