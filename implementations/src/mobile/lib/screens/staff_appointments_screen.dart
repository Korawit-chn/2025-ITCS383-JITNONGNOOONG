import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class StaffAppointmentsScreen extends StatefulWidget {
  const StaffAppointmentsScreen({super.key});

  @override
  State<StaffAppointmentsScreen> createState() => _StaffAppointmentsScreenState();
}

class _StaffAppointmentsScreenState extends State<StaffAppointmentsScreen> {
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

  Future<void> _confirmDate(String id) async {
    try {
      final response = await ApiService.put('/appointments/$id', body: {'action': 'CONFIRM_DATE'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'ยืนยันวันนัดแล้ว')),
        );
        await _loadAppointments();
      }
    } catch (e) {
      debugPrint('Confirm date error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถยืนยันวันนัดได้: $e')),
      );
    }
  }

  Future<void> _completeAppointment(String id) async {
    try {
      final response = await ApiService.put('/appointments/$id', body: {'status': 'COMPLETED'});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'อัปเดตสถานะเรียบร้อย')),
        );
        await _loadAppointments();
      }
    } catch (e) {
      debugPrint('Complete appointment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถปิดนัดหมายได้: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('นัดหมายรับสุนัข')),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _appointments.isEmpty
                ? const ListView(
                    children: [
                      SizedBox(height: 120),
                      Center(child: Text('ไม่มีนัดหมายในระบบ')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appointments.length,
                    itemBuilder: (context, index) {
                      final appt = _appointments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(appt['dogName'] ?? 'ไม่พบชื่อสุนัข'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ลูกค้า: ${appt['firstName'] ?? ''} ${appt['lastName'] ?? ''}'),
                              Text('วันที่: ${appt['deliveryDate'] ?? 'ยังไม่กำหนด'}'),
                              Text('สถานะ: ${appt['status'] ?? '-'}'),
                              Text('ยืนยันโดยเจ้าหน้าที่: ${appt['staffConfirmed'] == true ? 'ใช่' : 'รอ'}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: appt['deliveryDate'] != null ? () => _confirmDate(appt['id'].toString()) : null,
                                child: const Text('ยืนยันวันนัด'),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: appt['status'] != 'completed' ? () => _completeAppointment(appt['id'].toString()) : null,
                                child: const Text('เสร็จสิ้น'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
