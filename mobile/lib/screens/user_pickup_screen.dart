import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class UserPickupScreen extends StatefulWidget {
  const UserPickupScreen({super.key});

  @override
  State<UserPickupScreen> createState() => _UserPickupScreenState();
}

class _UserPickupScreenState extends State<UserPickupScreen> {
  bool _isLoading = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/appointments');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _appointments = List<dynamic>.from(data['appointments'] ?? []));
      }
    } catch (e) {
      debugPrint('Load appointments error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(String adoptionId) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;

    try {
      final response = await ApiService.post('/appointments', body: {
        'adoptionId': adoptionId,
        'deliveryDate': picked.toIso8601String().split('T').first,
      });
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'บันทึกวันรับสุนัขสำเร็จ')),
        );
        await _loadAppointments();
      } else {
        throw Exception(data['message'] ?? 'ไม่สามารถบันทึกวันที่ได้');
      }
    } catch (e) {
      debugPrint('Select pickup date error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถบันทึกวันที่รับสุนัขได้: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกวันรับสุนัข'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _appointments.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('ยังไม่มีนัดหมายสำหรับคุณ')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _appointments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(appointment['dogName'] ?? 'ไม่พบชื่อสุนัข'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('สถานะ: ${appointment['status'] ?? '-'}'),
                              Text('วันที่นัด: ${appointment['deliveryDate'] ?? 'ยังไม่กำหนด'}'),
                              Text('พนักงานยืนยัน: ${appointment['staffConfirmed'] == true ? 'ยืนยันแล้ว' : 'รอการยืนยัน'}'),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: () => _selectDate(appointment['adoptionId'].toString()),
                              child: const Text('เลือกวัน'),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
