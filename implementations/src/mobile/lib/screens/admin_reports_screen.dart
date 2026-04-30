import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  List<dynamic> _adopters = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final summaryRes = await ApiService.get('/reports/summary');
      final adoptersRes = await ApiService.get('/reports/potential-adopters');
      if (summaryRes.statusCode == 200) {
        final data = jsonDecode(summaryRes.body);
        setState(() => _summary = Map<String, dynamic>.from(data));
      }
      if (adoptersRes.statusCode == 200) {
        final data = jsonDecode(adoptersRes.body);
        setState(() => _adopters = List<dynamic>.from(data['adopters'] ?? []));
      }
    } catch (e) {
      debugPrint('Load admin reports error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSummaryCard(String label, dynamic value, Color color) {
    return Expanded(
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value?.toString() ?? '-', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แดชบอร์ดผู้ดูแลระบบ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('สรุปรายงาน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSummaryCard('รอพิจารณา', _summary?['adoptions']?['pending'] ?? '-', Colors.orange),
                      const SizedBox(width: 12),
                      _buildSummaryCard('อนุมัติ', _summary?['adoptions']?['approved'] ?? '-', Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSummaryCard('ปฏิเสธ', _summary?['adoptions']?['rejected'] ?? '-', Colors.red),
                      const SizedBox(width: 12),
                      _buildSummaryCard('ทั้งหมด', _summary?['adoptions']?['total'] ?? '-', Colors.blueGrey),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('ผู้มีแนวโน้มรับเลี้ยง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_adopters.isEmpty)
                    const Text('ยังไม่มีผู้มีแนวโน้มรับเลี้ยง')
                  else
                    ..._adopters.map((adopter) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('${adopter['firstName'] ?? ''} ${adopter['lastName'] ?? ''}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (adopter['email'] != null) Text('อีเมล: ${adopter['email']}'),
                              if (adopter['phone'] != null) Text('โทร: ${adopter['phone']}'),
                              if (adopter['citizen_id'] != null) Text('บัตรประชาชน: ${adopter['citizen_id']}'),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
