import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config.dart';

class SponsorDashboardScreen extends StatefulWidget {
  const SponsorDashboardScreen({super.key});

  @override
  State<SponsorDashboardScreen> createState() => _SponsorDashboardScreenState();
}

class _SponsorDashboardScreenState extends State<SponsorDashboardScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _sponsor;
  List<dynamic> _sponsors = [];
  final _donationController = TextEditingController();
  File? _pickedBanner;

  @override
  void initState() {
    super.initState();
    _loadSponsorData();
  }

  @override
  void dispose() {
    _donationController.dispose();
    super.dispose();
  }

  Future<void> _loadSponsorData() async {
    setState(() => _isLoading = true);
    try {
      final meResponse = await ApiService.get('/sponsors/me');
      final listResponse = await ApiService.get('/sponsors');
      if (meResponse.statusCode == 200) {
        final data = jsonDecode(meResponse.body);
        setState(() => _sponsor = data['sponsor'] != null ? Map<String, dynamic>.from(data['sponsor']) : null);
      }
      if (listResponse.statusCode == 200) {
        final data = jsonDecode(listResponse.body);
        setState(() => _sponsors = List<dynamic>.from(data['sponsors'] ?? []));
      }
      if (_sponsor != null) {
        _donationController.text = _sponsor?['donation_amount']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Load sponsor data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBanner() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _pickedBanner = File(image.path));
  }

  Future<void> _saveSponsor() async {
    if (_donationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกจำนวนเงินบริจาค')));
      return;
    }
    final amount = num.tryParse(_donationController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('จำนวนเงินไม่ถูกต้อง')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final response = await ApiService.postMultipart(
        '/sponsors/register',
        fields: {'donation_amount': amount.toString()},
        fileField: _pickedBanner != null ? 'banner' : null,
        file: _pickedBanner,
      );
      final body = await http.Response.fromStream(response);
      if (body.statusCode == 200) {
        final data = jsonDecode(body.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'บันทึกสำเร็จ')));
        await _loadSponsorData();
      } else {
        final data = jsonDecode(body.body);
        throw Exception(data['message'] ?? 'ไม่สามารถบันทึกได้');
      }
    } catch (e) {
      debugPrint('Save sponsor error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ไม่สามารถบันทึกข้อมูลผู้สนับสนุนได้: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (Uri.tryParse(url)?.hasScheme == true) return url;
    return '${Config.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ดผู้สนับสนุน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('สวัสดี ${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ข้อมูลผู้สนับสนุน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (_sponsor != null) ...[
                            Text('ยอดบริจาคปัจจุบัน: ${_sponsor?['donation_amount'] ?? '-'}'),
                            Text('ยอดรวม: ${_sponsor?['total_donated'] ?? '-'}'),
                          ] else
                            const Text('ยังไม่ได้ลงทะเบียนผู้สนับสนุน'),
                          const SizedBox(height: 12),
                          if (_sponsor?['banner_url'] != null)
                            Image.network(
                              _resolveUrl(_sponsor?['banner_url']?.toString()),
                              fit: BoxFit.cover,
                              height: 140,
                              width: double.infinity,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('ลงทะเบียน / อัปเดตผู้สนับสนุน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _donationController,
                    decoration: const InputDecoration(labelText: 'จำนวนเงินบริจาค', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(_pickedBanner == null ? 'เลือกแบนเนอร์' : 'เปลี่ยนแบนเนอร์'),
                    onPressed: _pickBanner,
                  ),
                  if (_pickedBanner != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Image.file(_pickedBanner!, height: 140, fit: BoxFit.cover),
                    ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSponsor,
                    child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('บันทึกข้อมูล'),
                  ),
                  const SizedBox(height: 24),
                  const Text('ผู้สนับสนุนอื่น ๆ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._sponsors.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'),
                        subtitle: Text('ยอดบริจาครวม: ${item['total_donated'] ?? '0'}'),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}
