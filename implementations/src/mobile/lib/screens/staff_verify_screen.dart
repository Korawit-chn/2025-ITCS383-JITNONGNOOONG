import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class StaffVerifyScreen extends StatefulWidget {
  const StaffVerifyScreen({super.key});

  @override
  State<StaffVerifyScreen> createState() => _StaffVerifyScreenState();
}

class _StaffVerifyScreenState extends State<StaffVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _citizenController = TextEditingController();
  final _adoptionController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _citizenController.dispose();
    _adoptionController.dispose();
    super.dispose();
  }

  Future<void> _runVerify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _result = null;
    });
    try {
      final response = await ApiService.post('/verify/all', body: {
        'citizen_id': _citizenController.text.trim(),
        if (_adoptionController.text.isNotEmpty) 'adoption_id': _adoptionController.text.trim(),
      });
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() => _result = Map<String, dynamic>.from(data));
      } else {
        throw Exception(data['message'] ?? 'ไม่สามารถตรวจสอบได้');
      }
    } catch (e) {
      debugPrint('Verify error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถตรวจสอบได้: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตรวจสอบผู้รับเลี้ยง')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _citizenController,
                    decoration: const InputDecoration(
                      labelText: 'เลขบัตรประชาชน',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกเลขบัตรประชาชน';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _adoptionController,
                    decoration: const InputDecoration(
                      labelText: 'หมายเลขคำขอ (ไม่บังคับ)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _runVerify,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ตรวจสอบข้อมูล'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_result != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ผลการตรวจสอบ: ${_result?['passed'] == true ? 'ผ่าน' : 'ไม่ผ่าน'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_result?['checks'] != null)
                        ...List<Widget>.from(((_result!['checks'] as Map<String, dynamic>).entries).map((entry) {
                          final item = Map<String, dynamic>.from(entry.value);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(item['message'] ?? '-'),
                              ],
                            ),
                          );
                        })),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
