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

  String _normalizeStatus(dynamic value) {
    return value?.toString().toLowerCase().trim() ?? '';
  }

  bool _canValidate(dynamic request) {
    final status = _normalizeStatus(request['status']);
    final verification = _normalizeStatus(request['verification_status']);
    return status == 'pending' && verification == 'pending';
  }

  bool _canApprove(dynamic request) {
    final status = _normalizeStatus(request['status']);
    final verification = _normalizeStatus(request['verification_status']);
    return status == 'pending' && verification == 'passed';
  }

  bool _canReject(dynamic request) {
    final status = _normalizeStatus(request['status']);
    return status == 'pending';
  }

  String _translateVerificationStatus(String? status) {
    switch (status?.toString().toLowerCase().trim()) {
      case 'passed':
        return 'ผ่าน';
      case 'failed':
        return 'ไม่ผ่าน';
      case 'pending':
        return 'รอตรวจสอบ';
      default:
        return '-';
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

  Future<void> _validateRequest(dynamic request) async {
    try {
      final response = await ApiService.post('/verify/all', body: {
        'citizen_id': request['citizen_id'],
        'adoption_id': request['id'],
      });
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final message = data['passed'] == true
            ? 'การตรวจสอบผ่านแล้ว'
            : 'การตรวจสอบไม่ผ่าน — กรุณาตรวจสอบข้อมูล';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        await _loadRequests();
      } else {
        throw Exception(data['message'] ?? 'ไม่สามารถตรวจสอบได้');
      }
    } catch (e) {
      debugPrint('Validate request error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถตรวจสอบได้: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการคำขอรับเลี้ยง')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadRequests,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _requests.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('ไม่มีคำขอให้พิจารณา')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            itemCount: _requests.length,
                            itemBuilder: (context, index) {
                              final request = _requests[index];
                              final status = _normalizeStatus(request['status']);
                              final verification = _normalizeStatus(request['verification_status']);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request['dogName'] ?? 'สุนัขไม่ระบุชื่อ',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text('ผู้ขอ: ${request['firstName'] ?? ''} ${request['lastName'] ?? ''}'),
                                      Text('สถานะตรวจสอบ: ${_translateVerificationStatus(request['verification_status'])}'),
                                      Text('สถานะคำขอ: ${request['status'] ?? '-'}'),
                                      if (status == 'pending' && verification == 'pending')
                                        const Text(
                                          'รอการตรวจสอบคุณสมบัติ',
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                      if (request['address'] != null) Text('ที่อยู่: ${request['address']}'),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (_canValidate(request))
                                            ElevatedButton(
                                              onPressed: () => _validateRequest(request),
                                              child: const Text('ตรวจสอบ'),
                                            ),
                                          if (_canApprove(request))
                                            ElevatedButton(
                                              onPressed: () => _reviewRequest(request, 'approve'),
                                              child: const Text('อนุมัติ'),
                                            ),
                                          if ((_canValidate(request) || _canApprove(request)) && _canReject(request))
                                            const SizedBox(width: 8),
                                          if (_canReject(request))
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () => _reviewRequest(request, 'reject'),
                                              child: const Text('ปฏิเสธ'),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
