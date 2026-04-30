import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class StaffCheckupsScreen extends StatefulWidget {
  const StaffCheckupsScreen({super.key});

  @override
  State<StaffCheckupsScreen> createState() => _StaffCheckupsScreenState();
}

class _StaffCheckupsScreenState extends State<StaffCheckupsScreen> {
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
      appBar: AppBar(title: const Text('ติดตามหลังรับเลี้ยง')),
      body: RefreshIndicator(
        onRefresh: _loadCheckups,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _checkups.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('ยังไม่มีข้อมูลติดตาม')), 
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _checkups.length,
                    itemBuilder: (context, index) {
                      final item = _checkups[index];
                      final staffFollowups = List<dynamic>.from(item['staff_followups'] ?? []);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(item['dog_name'] ?? 'ไม่พบชื่อสุนัข'),
                          subtitle: Text('สถานะ: ${item['delivery_status'] ?? '-'}'),
                          children: staffFollowups.isEmpty
                              ? [const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('ยังไม่มีบันทึกเจ้าหน้าที่'),
                                )]
                              : staffFollowups.map((followup) {
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
