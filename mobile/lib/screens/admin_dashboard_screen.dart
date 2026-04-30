import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  List<dynamic> _adopters = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
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
      debugPrint('Load admin dashboard error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Widget _buildGraphBar(String label, int count, int total, Color color) {
    final ratio = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  width: constraints.maxWidth,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text('$count รายการ', style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider authProvider) async {
    await authProvider.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final pending = _toInt(_summary?['adoptions']?['pending']);
    final approved = _toInt(_summary?['adoptions']?['approved']);
    final rejected = _toInt(_summary?['adoptions']?['rejected']);
    final total = _toInt(_summary?['adoptions']?['total']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ดผู้ดูแลระบบ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, authProvider),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สวัสดี ${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text('สรุปภาพรวมคำขอรับเลี้ยง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildGraphBar('รอพิจารณา', pending, total, Colors.orange),
                  const SizedBox(height: 16),
                  _buildGraphBar('อนุมัติ', approved, total, Colors.green),
                  const SizedBox(height: 16),
                  _buildGraphBar('ปฏิเสธ', rejected, total, Colors.red),
                  const SizedBox(height: 24),
                  const Text('ผู้รับเลี้ยงที่มีศักยภาพ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_adopters.isEmpty)
                    const Text('ยังไม่มีผู้รับเลี้ยงที่มีศักยภาพ')
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
                    }).toList(),
                ],
              ),
            ),
    );
  }

}