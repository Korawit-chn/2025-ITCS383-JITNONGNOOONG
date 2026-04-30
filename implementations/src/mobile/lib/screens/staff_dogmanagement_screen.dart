import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class StaffDogManagementScreen extends StatefulWidget {
  const StaffDogManagementScreen({super.key});

  @override
  State<StaffDogManagementScreen> createState() => _StaffDogManagementScreenState();
}

class _StaffDogManagementScreenState extends State<StaffDogManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _dogs = [];

  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/dogs');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _dogs = List<dynamic>.from(data['dogs'] ?? []));
      }
    } catch (e) {
      debugPrint('Load dogs error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDog(String dogId) async {
    try {
      final response = await ApiService.delete('/dogs/$dogId');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'ลบสุนัขสำเร็จ')));
        await _loadDogs();
      }
    } catch (e) {
      debugPrint('Delete dog error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถลบสุนัขได้: $e')),
      );
    }
  }

  Future<void> _showDogForm({Map<String, dynamic>? dog}) async {
    final nameController = TextEditingController(text: dog?['name'] ?? '');
    final breedController = TextEditingController(text: dog?['breed'] ?? '');
    final colorController = TextEditingController(text: dog?['color'] ?? '');
    final ageController = TextEditingController(text: dog?['age']?.toString() ?? '');
    final medicalController = TextEditingController(text: dog?['medical_profile'] ?? '');
    final trainingController = TextEditingController(text: dog?['training_status'] ?? '');
    String status = dog?['status'] ?? 'available';
    String gender = dog?['gender'] ?? 'unknown';

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dog == null ? 'เพิ่มสุนัขใหม่' : 'แก้ไขข้อมูลสุนัข'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'ชื่อ'),
                  validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกชื่อ' : null,
                ),
                TextFormField(
                  controller: breedController,
                  decoration: const InputDecoration(labelText: 'สายพันธุ์'),
                ),
                TextFormField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'สี'),
                ),
                TextFormField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'อายุ'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: const InputDecoration(labelText: 'เพศ'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('ผู้')),
                    DropdownMenuItem(value: 'female', child: Text('เมีย')),
                    DropdownMenuItem(value: 'unknown', child: Text('ไม่ระบุ')),
                  ],
                  onChanged: (value) => gender = value ?? 'unknown',
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'สถานะ'),
                  items: const [
                    DropdownMenuItem(value: 'available', child: Text('พร้อมรับเลี้ยง')),
                    DropdownMenuItem(value: 'pending', child: Text('รอดำเนินการ')),
                    DropdownMenuItem(value: 'adopted', child: Text('รับเลี้ยงแล้ว')),
                  ],
                  onChanged: (value) => status = value ?? 'available',
                ),
                TextFormField(
                  controller: medicalController,
                  decoration: const InputDecoration(labelText: 'ประวัติสุขภาพ'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: trainingController,
                  decoration: const InputDecoration(labelText: 'สถานะการฝึก'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final body = {
                'dogName': nameController.text.trim(),
                'breed': breedController.text.trim(),
                'color': colorController.text.trim(),
                'age': ageController.text.trim(),
                'gender': gender,
                'status': status,
                'medical_profile': medicalController.text.trim(),
                'training_status': trainingController.text.trim(),
              };
              try {
                final response = dog == null
                    ? await ApiService.post('/dogs', body: body)
                    : await ApiService.put('/dogs/${dog['id']}', body: body);
                final data = jsonDecode(response.body);
                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'บันทึกแล้ว')));
                  await _loadDogs();
                } else {
                  throw Exception(data['message'] ?? 'ไม่สามารถบันทึกได้');
                }
              } catch (e) {
                debugPrint('Dog save error: $e');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ไม่สามารถบันทึกสุนัขได้: $e')));
              }
            },
            child: Text(dog == null ? 'เพิ่ม' : 'บันทึก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการสุนัข'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDogForm(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDogs,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _dogs.isEmpty
                ? const ListView(
                    children: [
                      SizedBox(height: 120),
                      Center(child: Text('ยังไม่มีสุนัขในระบบ')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _dogs.length,
                    itemBuilder: (context, index) {
                      final dog = _dogs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(dog['name'] ?? 'ไม่ระบุชื่อ'),
                          subtitle: Text('${dog['breed'] ?? '-'} • ${dog['age'] ?? '-'} ปี'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showDogForm(dog: dog),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDog(dog['id'].toString()),
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
