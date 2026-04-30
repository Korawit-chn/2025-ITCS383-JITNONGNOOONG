import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class StaffAdoptionReqScreen extends StatefulWidget {
  const StaffAdoptionReqScreen({super.key});

  @override
  State<StaffAdoptionReqScreen> createState() => _StaffAdoptionReqScreenState();
}

class _StaffAdoptionReqScreenState extends State<StaffAdoptionReqScreen> {
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
      final response = await ApiService.get('/adoptions');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _requests = List<dynamic>.from(data['adoptions'] ?? []));
      }
    } catch (e) {
      debugPrint('Load adoption requests error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reviewRequest(dynamic request, String action) async {
    final rejectionReasonController = TextEditingController();
    String? rejectionReason;
    if (action == 'reject') {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('กรุณาระบุเหตุผลการปฏิเสธ'),
          content: TextField(
            controller: rejectionReasonController,
            decoration: const InputDecoration(hintText: 'เหตุผลการปฏิเสธ'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ส่ง')),
          ],
        ),
      );
      if (result != true) return;
      rejectionReason = rejectionReasonController.text.trim();
    }

    try {
      final response = await ApiService.put('/adoptions/${request['id']}/review', body: {
        'action': action,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      });
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'อัปเดตสถานะคำขอแล้ว')),
        );
        await _loadRequests();
      } else {
        throw Exception(data['message'] ?? 'ไม่สามารถดำเนินการได้');
      }
    } catch (e) {
      debugPrint('Review request error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถอัปเดตคำขอได้: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการคำขอรับเลี้ยง')),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _requests.isEmpty
                ? const ListView(
                    children: [
                      SizedBox(height: 120),
                      Center(child: Text('ไม่มีคำขอให้พิจารณา')),
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
                          title: Text(request['dogName'] ?? 'สุนัขไม่ระบุชื่อ'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ผู้ขอ: ${request['firstName'] ?? ''} ${request['lastName'] ?? ''}'),
                              Text('สถานะตรวจสอบ: ${request['verification_status'] ?? '-'}'),
                              Text('สถานะคำขอ: ${request['status'] ?? '-'}'),
                              if (request['address'] != null) Text('ที่อยู่: ${request['address']}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: request['status'] == 'pending'
                                    ? () => _reviewRequest(request, 'approve')
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: request['status'] == 'pending'
                                    ? () => _reviewRequest(request, 'reject')
                                    : null,
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
