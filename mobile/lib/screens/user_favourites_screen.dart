import 'dart:convert';

import 'package:flutter/material.dart';

import '../config.dart';
import '../services/api_service.dart';

class UserFavouritesScreen extends StatefulWidget {
  const UserFavouritesScreen({super.key});

  @override
  State<UserFavouritesScreen> createState() => _UserFavouritesScreenState();
}

class _UserFavouritesScreenState extends State<UserFavouritesScreen> {
  bool _isLoading = true;
  List<dynamic> _favourites = [];

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/favourites');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _favourites = List<dynamic>.from(data['favourites'] ?? []));
      }
    } catch (e) {
      debugPrint('Load favourites error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavourite(String dogId) async {
    try {
      await ApiService.delete('/favourites/$dogId');
      await _loadFavourites();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('นำสุนัขออกจากรายการโปรดแล้ว')),
      );
    } catch (e) {
      debugPrint('Remove favourite error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถลบรายการโปรดได้')),
      );
    }
  }

  String _resolveImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (Uri.tryParse(imageUrl)?.hasScheme == true) return imageUrl;
    return '${Config.baseUrl}$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สุนัขที่ชอบ'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavourites,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favourites.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('ยังไม่มีสุนัขที่ชอบ')), 
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favourites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final dog = _favourites[index];
                      return Card(
                        child: ListTile(
                          leading: dog['image_url'] != null
                              ? Image.network(
                                  _resolveImage(dog['image_url']?.toString()),
                                  width: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.pets),
                                )
                              : const Icon(Icons.pets),
                          title: Text(dog['name'] ?? 'ไม่ระบุชื่อ'),
                          subtitle: Text('${dog['breed'] ?? '-'} • ${dog['age'] ?? '-'} ปี'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeFavourite(dog['id'].toString()),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
