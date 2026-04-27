import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DogsScreen extends StatefulWidget {
  const DogsScreen({super.key});

  @override
  State<DogsScreen> createState() => _DogsScreenState();
}

class _DogsScreenState extends State<DogsScreen> {
  List<dynamic> _dogs = [];
  bool _isLoading = true;
  String _searchKeyword = '';
  String _selectedBreed = '';
  List<String> _breeds = [];

  @override
  void initState() {
    super.initState();
    _fetchDogs();
    _fetchBreeds();
  }

  Future<void> _fetchDogs() async {
    setState(() => _isLoading = true);
    try {
      final queryParams = {
        if (_searchKeyword.isNotEmpty) 'keyword': _searchKeyword,
        if (_selectedBreed.isNotEmpty) 'breed': _selectedBreed,
      };

      final uri = Uri.parse('http://localhost:3000/api/dogs').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() => _dogs = data['data']);
        }
      }
    } catch (e) {
      print('Error fetching dogs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBreeds() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/dogs/breeds'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() => _breeds = List<String>.from(data['data']));
        }
      }
    } catch (e) {
      print('Error fetching breeds: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐶 สุนัขรอหาบ้าน'),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'ค้นหาชื่อ...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _searchKeyword = value;
                    _fetchDogs();
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('สายพันธุ์: '),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedBreed.isEmpty ? null : _selectedBreed,
                        hint: const Text('ทั้งหมด'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: '', child: Text('ทั้งหมด')),
                          ..._breeds.map((breed) => DropdownMenuItem(
                                value: breed,
                                child: Text(breed),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedBreed = value ?? '');
                          _fetchDogs();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dogs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _dogs.isEmpty
                    ? const Center(child: Text('ไม่พบสุนัข'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _dogs.length,
                        itemBuilder: (context, index) {
                          final dog = _dogs[index];
                          return _buildDogCard(dog);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDogCard(dynamic dog) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dog Image
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.grey.shade200,
            child: dog['imageUrl'] != null
                ? Image.network(
                    'http://localhost:3000${dog['imageUrl']}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.pets, size: 48)),
                  )
                : const Center(child: Icon(Icons.pets, size: 48)),
          ),

          // Dog Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dog['name'] ?? 'ไม่มีชื่อ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dog['breed'] ?? 'ไม่ระบุสายพันธุ์'} • ${dog['age'] ?? 0} ปี',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(dog['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(dog['status']),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
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

  String _getStatusText(String? status) {
    switch (status) {
      case 'available':
        return 'พร้อมรับเลี้ยง';
      case 'pending':
        return 'รอดำเนินการ';
      case 'adopted':
        return 'รับเลี้ยงแล้ว';
      default:
        return 'ไม่ระบุ';
    }
  }
}