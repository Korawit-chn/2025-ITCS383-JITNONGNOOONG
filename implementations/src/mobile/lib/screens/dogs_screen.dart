import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class DogsScreen extends StatefulWidget {
  const DogsScreen({super.key});

  @override
  State<DogsScreen> createState() => _DogsScreenState();
}

class _DogsScreenState extends State<DogsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allDogs = [];
  List<dynamic> _filteredDogs = [];
  bool _isLoading = true;
  String _searchKeyword = '';
  String _selectedBreed = '';
  String _selectedColor = '';
  String _selectedTrainingStatus = '';
  bool _availableOnly = false;
  List<String> _breeds = [];
  List<String> _colors = [];
  List<String> _trainingStatuses = [];

  // Training status mapping (from Thai UI labels to DB values)
  static const Map<String, List<String>> trainingMap = {
    'ยังไม่ผ่านการฝึก': ['ยังไม่ผ่านการฝึก'],
    'ผ่านการฝึกขั้นต้น': ['ผ่านการฝึกขั้นต้น', 'ขั้นต้น'],
    'ผ่านการฝึกขั้นสูง': ['ผ่านการฝึกขั้นสูง', 'ขั้นสูง'],
    'ผ่านการฝึกพื้นฐาน': ['ผ่านการฝึกพื้นฐาน', 'ผ่านการฝึก'],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('${Config.apiBase}/dogs');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic>? dogs;
        if (data is Map<String, dynamic> && data['dogs'] != null) {
          dogs = List<dynamic>.from(data['dogs']);
        }

        if (dogs != null) {
          final breeds = dogs
              .map((dog) => dog['breed']?.toString())
              .whereType<String>()
              .where((breed) => breed.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final colors = dogs
              .map((dog) => dog['color']?.toString())
              .whereType<String>()
              .where((color) => color.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          final trainingStatuses = dogs
              .map((dog) => dog['training_status']?.toString())
              .whereType<String>()
              .where((status) => status.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          setState(() {
            _allDogs = dogs!;
            _filteredDogs = dogs;
            _breeds = breeds;
            _colors = colors;
            _trainingStatuses = trainingStatuses;
          });
          _performClientSideFilter();
        } else {
          print('Fetch responded with unexpected JSON shape: $data');
        }
      } else {
        print('Fetch failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error loading dogs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\u0E00-\u0E7Fa-z0-9]'), '');
  }

  void _performClientSideFilter() {
    setState(() {
      _filteredDogs = _allDogs.where((dog) {
        // Keyword search (normalize Thai and English)
        if (_searchKeyword.isNotEmpty) {
          final kw = _normalizeText(_searchKeyword);
          final dogName = _normalizeText(dog['name']?.toString() ?? '');
          final dogBreed = _normalizeText(dog['breed']?.toString() ?? '');
          if (!dogName.contains(kw) && !dogBreed.contains(kw)) {
            return false;
          }
        }

        // Breed filter
        if (_selectedBreed.isNotEmpty && dog['breed']?.toString() != _selectedBreed) {
          return false;
        }

        // Color filter
        if (_selectedColor.isNotEmpty && dog['color']?.toString() != _selectedColor) {
          return false;
        }

        // Training status filter (with mapping)
        if (_selectedTrainingStatus.isNotEmpty) {
          final targets = trainingMap[_selectedTrainingStatus] ?? [];
          final dogTraining = (dog['training_status']?.toString() ?? '').toLowerCase();
          if (!targets.any((t) => dogTraining == t.toLowerCase())) {
            return false;
          }
        }

        // Availability filter
        if (_availableOnly) {
          final status = (dog['status']?.toString() ?? '').toLowerCase().trim();
          if (status != 'available') {
            return false;
          }
        }

        return true;
      }).toList();
    });
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
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาชื่อ...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        setState(() => _searchKeyword = _searchController.text.trim());
                        _performClientSideFilter();
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchKeyword = value.trim());
                    _performClientSideFilter();
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
                          _performClientSideFilter();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedColor.isEmpty ? null : _selectedColor,
                        hint: const Text('สี'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: '', child: Text('ทั้งหมด')),
                          ..._colors.map((color) => DropdownMenuItem(
                                value: color,
                                child: Text(color),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedColor = value ?? '');
                          _performClientSideFilter();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedTrainingStatus.isEmpty ? null : _selectedTrainingStatus,
                        hint: const Text('การฝึก'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: '', child: Text('ทั้งหมด')),
                          ..._trainingStatuses.map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedTrainingStatus = value ?? '');
                          _performClientSideFilter();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _availableOnly,
                  title: const Text('เฉพาะสุนัขพร้อมรับเลี้ยง'),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() => _availableOnly = value ?? false);
                    _performClientSideFilter();
                  },
                ),
              ],
            ),
          ),

          // Dogs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            if (_searchKeyword.isNotEmpty ||
                                _selectedBreed.isNotEmpty ||
                                _selectedColor.isNotEmpty ||
                                _selectedTrainingStatus.isNotEmpty ||
                                _availableOnly)
                              const Text(
                                'ไม่พบสุนัขที่ตรงกับเงื่อนไข',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              )
                            else
                              const Text(
                                'ยังไม่มีสุนัขในระบบ',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filteredDogs.length,
                        itemBuilder: (context, index) {
                          final dog = _filteredDogs[index];
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
            child: () {
              final imageUrl = dog['image_url']?.toString();
              if (imageUrl == null || imageUrl.isEmpty) {
                return const Center(child: Icon(Icons.pets, size: 48));
              }
              final resolvedUrl = Uri.tryParse(imageUrl)?.hasScheme == true
                  ? imageUrl
                  : '${Config.baseUrl}$imageUrl';
              return Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.pets, size: 48)),
              );
            }(),
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