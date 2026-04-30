import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config.dart';

class DogDetailScreen extends StatefulWidget {
  const DogDetailScreen({super.key});

  @override
  State<DogDetailScreen> createState() => _DogDetailScreenState();
}

class _DogDetailScreenState extends State<DogDetailScreen> {
  Map<String, dynamic>? _dog;
  bool _isLoading = true;
  bool _isFavourite = false;
  bool _isSubmitting = false;
  final _addressController = TextEditingController();
  final _messageController = TextEditingController();
  String _livingType = 'house';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dogId = ModalRoute.of(context)?.settings.arguments;
      if (dogId is int || dogId is String) {
        _loadDog(dogId.toString());
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadDog(String id) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/dogs/$id');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _dog = Map<String, dynamic>.from(data['dog'] ?? {});
        });
        await _loadFavouriteState(id);
      }
    } catch (e) {
      debugPrint('Dog detail load error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavouriteState(String id) async {
    try {
      final response = await ApiService.get('/favourites');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = List<dynamic>.from(data['favourites'] ?? []);
        setState(() {
          _isFavourite = list.any((item) => item['id']?.toString() == id);
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavourite() async {
    if (_dog == null) return;
    final id = _dog!['id'];
    try {
      if (_isFavourite) {
        await ApiService.delete('/favourites/$id');
      } else {
        await ApiService.post('/favourites/$id');
      }
      setState(() => _isFavourite = !_isFavourite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFavourite ? 'เพิ่มเข้าสู่รายการโปรดแล้ว' : 'นำออกจากรายการโปรดแล้ว')),
      );
    } catch (e) {
      debugPrint('Favourite toggle error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถอัปเดตรายการโปรดได้')),
      );
    }
  }

  Future<void> _submitAdoption() async {
    if (_dog == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    final dogId = _dog!['id'];
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกที่อยู่สำหรับรับเลี้ยง')), 
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final response = await ApiService.post('/adoptions', body: {
        'dogId': dogId,
        'address': _addressController.text.trim(),
        'livingType': _livingType,
        'message': _messageController.text.trim(),
      });
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'ยื่นคำขอสำเร็จ')),
        );
        Navigator.pop(context);
      } else {
        throw Exception(data['message'] ?? 'Adoption failed');
      }
    } catch (e) {
      debugPrint('Adopt error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถส่งคำขอรับเลี้ยงได้: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _resolveImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    final parsed = Uri.tryParse(imageUrl);
    if (parsed != null && parsed.hasScheme) return imageUrl;
    return '${Config.baseUrl}$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดสุนัข'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dog == null
              ? const Center(child: Text('ไม่พบข้อมูลสุนัข'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.shade200,
                          image: _dog!['image_url'] != null
                              ? DecorationImage(
                                  image: NetworkImage(_resolveImage(_dog!['image_url']?.toString())),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _dog!['image_url'] == null
                            ? const Center(child: Icon(Icons.pets, size: 80))
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _dog!['name'] ?? 'ไม่มีชื่อ',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_isFavourite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                            onPressed: _toggleFavourite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${_dog!['breed'] ?? 'ไม่ระบุสายพันธุ์'} • อายุ ${_dog!['age'] ?? '-'} ปี',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          (_dog!['status'] ?? 'ไม่ระบุ').toString().toUpperCase(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_dog!['medical_profile'] != null && _dog!['medical_profile'].toString().isNotEmpty) ...[
                        const Text('ประวัติสุขภาพ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_dog!['medical_profile'] ?? ''),
                        const SizedBox(height: 16),
                      ],
                      if (_dog!['training_status'] != null && _dog!['training_status'].toString().isNotEmpty) ...[
                        const Text('สถานะการฝึก', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_dog!['training_status'] ?? ''),
                        const SizedBox(height: 16),
                      ],
                      const Text('ส่งคำขอรับเลี้ยง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'ที่อยู่สำหรับรับเลี้ยง',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _livingType,
                        decoration: const InputDecoration(labelText: 'ประเภทที่พัก', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'house', child: Text('บ้านเดี่ยว')),
                          DropdownMenuItem(value: 'condo', child: Text('คอนโด')),
                          DropdownMenuItem(value: 'apartment', child: Text('อพาร์ตเมนต์')),
                          DropdownMenuItem(value: 'townhouse', child: Text('ทาวน์เฮาส์')),
                        ],
                        onChanged: (value) => setState(() => _livingType = value ?? 'house'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'เกร็ดความประทับใจ / เหตุผลที่ต้องการรับเลี้ยง',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAdoption,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('ยื่นคำขอรับเลี้ยง'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
