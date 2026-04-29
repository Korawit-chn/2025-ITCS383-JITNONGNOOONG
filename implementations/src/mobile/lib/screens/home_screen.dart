import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../config.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _dogs = [];
  String? _bannerUrl;
  bool _isLoadingDogs = true;
  bool _isLoadingSponsor = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    await Future.wait([_fetchDogs(), _fetchSponsorBanner()]);
  }

  Future<void> _fetchDogs() async {
    setState(() => _isLoadingDogs = true);
    try {
      final response = await http.get(Uri.parse('${Config.apiBase}/dogs'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['dogs'] != null) {
          final dogs = List<dynamic>.from(data['dogs']);
          setState(() => _dogs = dogs.take(6).toList());
        } else {
          print('Home fetch dogs responded with unexpected JSON shape: $data');
        }
      } else {
        print('Home fetch dogs failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error fetching home dogs: $e');
    } finally {
      setState(() => _isLoadingDogs = false);
    }
  }

  Future<void> _fetchSponsorBanner() async {
    setState(() => _isLoadingSponsor = true);
    try {
      final response = await http.get(Uri.parse('${Config.apiBase}/sponsors'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['sponsors'] != null) {
          final sponsors = List<dynamic>.from(data['sponsors']);
          final latest = sponsors.cast<Map<String, dynamic>>().firstWhere(
                (s) => s['banner_url'] != null && s['banner_url'].toString().isNotEmpty,
                orElse: () => {},
              );
          if (latest.isNotEmpty) {
            setState(() => _bannerUrl = _resolveImageUrl(latest['banner_url']?.toString()));
          }
        } else {
          print('Home fetch sponsors responded with unexpected JSON shape: $data');
        }
      } else {
        print('Home fetch sponsors failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error fetching sponsor banner: $e');
    } finally {
      setState(() => _isLoadingSponsor = false);
    }
  }

  String? _resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;
    return '${Config.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('JITNONGNOONG'),
        actions: [
          if (authProvider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authProvider.logout(),
            )
          else
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('เข้าสู่ระบบ'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'ให้น้องสุนัขมีบ้านที่รัก',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ระบบรับเลี้ยงสุนัขขององค์กรไม่แสวงหาผลกำไร ครบครัน โปร่งใส ดูแลต่อเนื่อง',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/dogs'),
                        child: const Text('🐶 ดูสุนัขรอหาบ้าน'),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('วิธีการรับเลี้ยง'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ผู้สนับสนุน',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: _isLoadingSponsor
                        ? const Center(child: CircularProgressIndicator())
                        : _bannerUrl != null
                            ? Image.network(
                                _bannerUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Text('ไม่สามารถโหลดแบนเนอร์ได้'),
                                ),
                              )
                            : const Center(child: Text('ยังไม่มีแบนเนอร์ผู้สนับสนุน')),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'น้องรอหาบ้าน',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'สุนัขพร้อมรับเลี้ยง',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ทุกตัวผ่านการตรวจสุขภาพ ฉีดวัคซีน และฝึกนิสัยพื้นฐานแล้ว',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  _isLoadingDogs
                      ? const Center(child: CircularProgressIndicator())
                      : _dogs.isEmpty
                          ? const Center(child: Text('ไม่พบสุนัข'))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _dogs.length,
                              itemBuilder: (context, index) {
                                final dog = _dogs[index];
                                return _buildDogCard(dog);
                              },
                            ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/dogs'),
                      child: const Text('ดูสุนัขทั้งหมด →'),
                    ),
                  ),
                ],
              ),
            ),

            // How it works
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  const Text(
                    'ขั้นตอน',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'วิธีการรับเลี้ยงสุนัข',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ง่าย 4 ขั้นตอน เพื่อให้น้องได้บ้านที่ดีที่สุด',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStep('🔍', 'ขั้นที่ 1', 'ค้นหาสุนัข', 'เลือกดูสุนัขที่คุณชอบ'),
                      ),
                      Expanded(
                        child: _buildStep('📝', 'ขั้นที่ 2', 'ยื่นคำขอ', 'กรอกแบบฟอร์มรับเลี้ยง'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStep('✅', 'ขั้นที่ 3', 'ตรวจสอบคุณสมบัติ', 'ตรวจประวัติ'),
                      ),
                      Expanded(
                        child: _buildStep('🏠', 'ขั้นที่ 4', 'รับน้องกลับบ้าน', 'นัดรับน้อง'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String icon, String step, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(step, style: const TextStyle(color: Colors.blue)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildDogCard(dynamic dog) {
    final imageUrl = _resolveImageUrl(dog['image_url']?.toString());
    final status = dog['status']?.toString() ?? 'unknown';
    final gender = dog['gender']?.toString() ?? 'unknown';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.pets, size: 48)),
                    )
                  : const Center(child: Icon(Icons.pets, size: 48)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dog['name'] ?? 'ไม่มีชื่อ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '${dog['breed'] ?? 'ไม่ทราบ'} · ${dog['age'] ?? '—'} ปี · ${gender == 'female' ? 'เมีย' : gender == 'male' ? 'ผู้' : '—'}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'adopted':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'พร้อมรับเลี้ยง';
      case 'pending':
        return 'มีผู้สนใจ';
      case 'adopted':
        return 'รับเลี้ยงแล้ว';
      default:
        return 'ไม่ระบุ';
    }
  }
}
